import 'package:flutter/material.dart';
import '../auth_screens/login_screen.dart';
import '../models/auth_utility.dart';

class SessionExpiredHandler {
  SessionExpiredHandler._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static int _consecutive403 = 0;
  static const _max403BeforeLogout = 1;

  static Future<void> handle() async {
    _consecutive403 = 0;
    await AuthUtility.clearUserInfo();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static void resetForbiddenCount() {
    _consecutive403 = 0;
  }

  static void handleForbidden() {
    _consecutive403++;
    if (_consecutive403 >= _max403BeforeLogout) {
      handle();
    }
  }
}
