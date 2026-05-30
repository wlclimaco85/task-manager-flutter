import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/auth_utility.dart';
import 'auth_screens/login_screen.dart';
import 'utils/security_matrix.dart';
import 'utils/grid_theme.dart';
import 'web/screens/bottom_navbar_screen.dart';
import 'mobile/screens/bottom_navbar_screen.dart';
import 'windows/screens/bottom_navbar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  // Inicializa Hive para vendas em contingência NFC-e
  await Hive.initFlutter();
  await Hive.openBox('vendas_contingencia');
  // Inicializa SharedPreferences
  await SharedPreferences.getInstance();
  final bool loggedIn = await AuthUtility.isUserLoggedIn();
  if (loggedIn) {
    await ModuloAccess.load();
  }
  runApp(TaskManagerApp(loggedIn: loggedIn));
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
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: appTheme(),
      home: home,
    );
  }
}
