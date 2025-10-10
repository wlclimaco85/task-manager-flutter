import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/screens/splash_screens.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/bottom_navbar_screen.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});
  static GlobalKey<NavigatorState> globalKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalKey,
      debugShowCheckedModeBanner: false,
      title: "Gestão Contabil",
      theme: ThemeData(
        useMaterial3: true, // Opcional: para usar Material 3
        colorScheme: const ColorScheme.light(
          primary: GridColors.primary, // Vermelho da logo
          secondary: GridColors.secondary, // Verde da logo
          surface: GridColors.card, // Branco para superfícies
          background: GridColors.background, // Verde para fundo
          onPrimary: GridColors.textPrimary, // Branco para texto sobre vermelho
          onSecondary: GridColors.textPrimary, // Branco para texto sobre verde
          onSurface: GridColors.textSecondary, // Preto para texto sobre branco
          onBackground: GridColors.textPrimary, // Branco para texto sobre verde
          error: GridColors.error, // Vermelho para errors
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Inglês
        Locale('pt', 'BR'), // Português
      ],
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const BottomNavBarScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
