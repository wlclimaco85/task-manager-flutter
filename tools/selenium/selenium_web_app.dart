import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';

import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/web/screens/bottom_navbar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();

  AuthUtility.userInfo = LoginModel(
    status: 'success',
    token: 'selenium-local-token',
    data: Data(
      id: 9001,
      email: 'selenium@appacademia.local',
      firstName: 'Selenium',
      lastName: 'Tester',
    ),
    login: Login(
      id: 9001,
      email: 'selenium@appacademia.local',
      nome: 'Selenium Tester',
      tipoLogin: LoginEnum.MASTER,
    ),
    permissoes: const [],
  );

  runApp(const SeleniumTaskManagerApp());
}

int _initialScreenIndex() {
  return int.tryParse(Uri.base.queryParameters['screen'] ?? '') ?? 31;
}

class SeleniumTaskManagerApp extends StatelessWidget {
  const SeleniumTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager Selenium',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Semantics(
        label: 'selenium_authenticated_shell',
        child: WebBottomNavBarScreen(initialIndex: _initialScreenIndex()),
      ),
    );
  }
}
