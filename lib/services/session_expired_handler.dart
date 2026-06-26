import 'package:flutter/material.dart';
import '../auth_screens/login_screen.dart';
import '../models/auth_utility.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> handle() async {
    await AuthUtility.clearUserInfo();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
