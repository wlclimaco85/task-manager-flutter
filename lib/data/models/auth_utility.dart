// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';

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
      print('Erro ao recuperar user_data: $e');
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
    }

    return isLogin && userInfo != null;
  }
}
