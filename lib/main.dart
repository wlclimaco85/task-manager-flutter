// LOG DE DIAGNÓSTICO TEMPORÁRIO: usa print() de propósito para sair no console
// do navegador. Remover/reduzir verbosidade após localizar a causa do crash.
// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/auth_utility.dart';
import 'auth_screens/login_screen.dart';
import 'utils/grid_colors.dart';
import 'utils/security_matrix.dart';
import 'utils/app_logger.dart';
import 'utils/boot_recovery.dart';
import 'web/screens/bottom_navbar_screen.dart';
import 'mobile/screens/bottom_navbar_screen.dart';
import 'windows/screens/bottom_navbar_screen.dart';

// Prefixos de log: [BOOT] etapa ok · [BOOT-ERR] falha tolerada · [APP-ERROR] erro de runtime.
void _log(String msg) => print('[BOOT] $msg');
void _logErr(String tag, Object e, [StackTrace? s]) =>
    print('[BOOT-ERR] $tag: $e${s != null ? '\n$s' : ''}');

void main() {
  // runZonedGuarded captura erros assíncronos não tratados em qualquer ponto.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    _log('WidgetsFlutterBinding pronto');

    // Erros do framework -> console (com biblioteca/contexto/stack, que apontam o widget).
    FlutterError.onError = (FlutterErrorDetails details) {
      print('[APP-ERROR] FlutterError: ${details.exceptionAsString()}');
      print('[APP-ERROR] biblioteca: ${details.library} | contexto: ${details.context}');
      print('[APP-ERROR] stack:\n${details.stack}');
      FlutterError.presentError(details);
    };
    try {
      AppLogger.i.initCapture();
      _log('AppLogger.initCapture ok');
    } catch (e, s) {
      _logErr('AppLogger.initCapture', e, s);
    }

    // Em vez da tela rosa / ErrorWidget mudo, mostra tela amigável. O erro
    // detalhado já sai pelo FlutterError.onError acima — aqui não duplicar.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      print('[APP-ERROR] _BootErrorScreen exibida (detalhes acima via FlutterError).');
      return const _BootErrorScreen();
    };

    try {
      await initializeDateFormatting('pt_BR', null);
      _log('initializeDateFormatting ok');
    } catch (e, s) {
      _logErr('initializeDateFormatting', e, s);
    }

    try {
      await Hive.initFlutter();
      _log('Hive.initFlutter ok');
    } catch (e, s) {
      _logErr('Hive.initFlutter', e, s);
    }

    // Blindagem: box corrompida não pode derrubar o app antes do runApp.
    try {
      await Hive.openBox('vendas_contingencia');
      _log('openBox vendas_contingencia ok');
    } catch (e, s) {
      _logErr('openBox vendas_contingencia (tentando recriar)', e, s);
      try {
        await Hive.deleteBoxFromDisk('vendas_contingencia');
        await Hive.openBox('vendas_contingencia');
        _log('box vendas_contingencia recriada após corrupção');
      } catch (e2, s2) {
        _logErr('recriação da box vendas_contingencia', e2, s2);
      }
    }

    // Blindagem: sessão corrompida -> limpa e cai para login em vez de crashar.
    bool loggedIn = false;
    try {
      loggedIn = await AuthUtility.isUserLoggedIn();
      _log('isUserLoggedIn = $loggedIn');
    } catch (e, s) {
      _logErr('isUserLoggedIn (limpando sessão)', e, s);
      try {
        await AuthUtility.clearUserInfo();
      } catch (_) {}
      loggedIn = false;
    }

    if (loggedIn) {
      try {
        await ModuloAccess.load();
        _log('ModuloAccess.load ok');
      } catch (e, s) {
        _logErr('ModuloAccess.load', e, s);
      }
    }

    _log('runApp');
    runApp(TaskManagerApp(loggedIn: loggedIn));
  }, (error, stack) {
    print('[APP-ERROR] erro não tratado: $error');
    print('[APP-ERROR] stack:\n$stack');
  });
}

class TaskManagerApp extends StatelessWidget {
  final bool loggedIn;
  const TaskManagerApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    Widget home;

    if (loggedIn) {
      if (kIsWeb) {
        home = const WebBottomNavBarScreen();
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        home = const WindowsBottomNavBarScreen();
      } else {
        home = const BottomNavBarScreen();
      }
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: ThemeData(
        // Sobrescreve surface/background do Material 3 para evitar o fundo rosa
        // gerado automaticamente pelo fromSeed com seed vermelho
        colorScheme: ColorScheme.fromSeed(
          seedColor: GridColors.primary,
          surface: GridColors.background,
        ),
        scaffoldBackgroundColor: GridColors.background,
        useMaterial3: true,
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

/// Tela exibida quando o build de um widget falha (substitui o "fundo rosa" /
/// ErrorWidget padrão). Oferece limpar dados locais e recarregar — caminho de
/// recuperação para cache antigo ou storage corrompido.
class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: GridColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 56, color: GridColors.error),
                  const SizedBox(height: 16),
                  const Text(
                    'Não foi possível carregar o sistema',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Isso costuma ser causado por dados antigos guardados neste '
                    'navegador. Limpe os dados locais e recarregue para resolver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => limparDadosLocaisERecarregar(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar dados e recarregar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
