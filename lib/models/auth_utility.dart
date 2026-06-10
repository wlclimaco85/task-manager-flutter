// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/login_model.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';

// ---------------------------------------------------------------------------
// Utilitário para decodificar e verificar expiração do JWT sem biblioteca extra
// ---------------------------------------------------------------------------
bool _isJwtExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    // Adiciona padding base64 se necessário
    String payload = parts[1];
    final rem = payload.length % 4;
    if (rem != 0) payload += '=' * (4 - rem);
    final decoded = utf8.decode(base64Url.decode(payload));
    final json = jsonDecode(decoded) as Map<String, dynamic>;
    final exp = json['exp'];
    if (exp == null) return false; // sem expiração = não expira
    final expDate = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    return DateTime.now().isAfter(expDate);
  } catch (_) {
    return true; // se não conseguir decodificar, considera expirado
  }
}
class AuthUtility {
  static LoginModel? userInfo;

  static Future<void> setUserInfo(LoginModel model) async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    await _sharedPreferences.setString("user_data", jsonEncode(model.toJson()));
    userInfo = model;
  }

  static Future<LoginModel?> getUserInfo() async {
    try {
      SharedPreferences _sharedPreferences =
          await SharedPreferences.getInstance();
      String? value = _sharedPreferences.getString("user_data");

      if (value == null) return null;

      Map<String, dynamic> jsonData = jsonDecode(value);
      return LoginModel.fromJson(jsonData);
    } catch (e) {
      L.d('Erro ao recuperar user_data: $e');
      return null;
    }
  }

  static Future<void> clearUserInfo() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    await _sharedPreferences.remove("user_data");
    userInfo = null;
  }

  static Future<bool> isUserLoggedIn() async {
    SharedPreferences _sharedPreferences =
        await SharedPreferences.getInstance();
    bool isLogin = _sharedPreferences.containsKey("user_data");

    if (isLogin) {
      userInfo = await getUserInfo();
      // Se o token armazenado estiver expirado, força novo login
      if (userInfo?.token != null && _isJwtExpired(userInfo!.token!)) {
        L.w('[AuthUtility] token expirado — limpando sessão e forçando re-login');
        await clearUserInfo();
        return false;
      }
    }

    return isLogin && userInfo != null;
  }
}
