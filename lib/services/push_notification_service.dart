import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'network_caller.dart';
import '../utils/tenant_context.dart';

const String _firebaseAndroidApiKey =
    String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
const String _firebaseAndroidAppId =
    String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const String _firebaseMessagingSenderId =
    String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const String _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const String _firebaseStorageBucket =
    String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

FirebaseOptions? _firebaseOptionsFromEnvironment() {
  if (_firebaseAndroidApiKey.isEmpty ||
      _firebaseAndroidAppId.isEmpty ||
      _firebaseMessagingSenderId.isEmpty ||
      _firebaseProjectId.isEmpty) {
    return null;
  }

  return const FirebaseOptions(
    apiKey: _firebaseAndroidApiKey,
    appId: _firebaseAndroidAppId,
    messagingSenderId: _firebaseMessagingSenderId,
    projectId: _firebaseProjectId,
    storageBucket: _firebaseStorageBucket,
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    final options = _firebaseOptionsFromEnvironment();
    if (options == null) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: options);
    }
  } catch (_) {
    // Sem configuracao Firebase, nao ha como processar push nativo.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static bool _firebaseInicializado = false;
  static bool _listenerRegistrado = false;

  static bool get _suportaPushNativo =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> inicializarFirebaseSeDisponivel() async {
    if (!_suportaPushNativo || _firebaseInicializado) {
      return;
    }
    try {
      final options = _firebaseOptionsFromEnvironment();
      if (options == null) {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(options: options);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _firebaseInicializado = true;
    } catch (e) {
      L.w('[Push] Firebase nao configurado para este build: $e');
    }
  }

  static Future<void> registrarDispositivoLogado() async {
    if (!_suportaPushNativo) {
      return;
    }

    await inicializarFirebaseSeDisponivel();
    if (!_firebaseInicializado) {
      return;
    }

    final login =
        AuthUtility.userInfo?.login ?? (await AuthUtility.obterLogin())?.login;
    final loginId = login?.id ?? TenantContext.userId;
    if (loginId == null) {
      L.w('[Push] loginId ausente; token FCM nao registrado.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _enviarToken(loginId, token);
      }

      if (!_listenerRegistrado) {
        _listenerRegistrado = true;
        messaging.onTokenRefresh.listen((novoToken) {
          final loginAtual = TenantContext.userId;
          if (loginAtual != null) {
            _enviarToken(loginAtual, novoToken);
          }
        });
      }
    } catch (e) {
      L.w('[Push] falha ao registrar token FCM: $e');
    }
  }

  static Future<void> _enviarToken(int loginId, String token) async {
    if (token.isEmpty) {
      return;
    }
    final plataforma = defaultTargetPlatform.name.toUpperCase();
    final response = await NetworkCaller().postRequest(ApiLinks.deviceToken, {
      'loginId': loginId,
      'token': token,
      'plataforma': plataforma,
    });
    if (!response.isSuccess) {
      L.w('[Push] backend recusou device token. status=${response.statusCode}');
    }
  }
}
