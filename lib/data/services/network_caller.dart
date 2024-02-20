import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';

class NetworkCaller {
  Future<NetworkResponse> getRequest(String url) async {
    try {
      Response response = await get(Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthUtility.userInfo.token}'});
      if (response.statusCode == 200) {
        return NetworkResponse(
            true, response.statusCode, jsonDecode(response.body));
      } else {
        return NetworkResponse(
          false,
          response.statusCode,
          null,
        );
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(
      false,
      -1,
      null,
    );
  }

  Future<NetworkResponse> postRequest(
    String url,
    Map<String, dynamic>? body,
  ) async {
    try {
      //  if (url.contains('inserirAluno') && AuthUtility.userInfo.token == null) {
      //   AuthUtility.userInfo.token =
      //        "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3bGNsaW1hY29AZ21haWwuY29tIiwiZmlyc3ROYW1lIjoid2xjbGltYWNvQGdtYWlsLmNvbSIsImxhc3ROYW1lIjoid2xjbGltYWNvQGdtYWlsLmNvbSIsImV4cCI6MTkxNzgxMjg2Nn0._M1meDtyoQOMh3m30S4clJXu42SD-kGrjxkJ-4xeLVI";
      //  }
      Response response = await post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=ISO-8859-1',
          'Authorization': url.contains('login') || url.contains('inserirAluno')
              ? 'c2Fua2h5YTpzdXA='
              : 'Bearer ${AuthUtility.userInfo.token}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
            true, response.statusCode, jsonDecode(response.body));
      } else {
        return NetworkResponse(
          false,
          response.statusCode,
          null,
        );
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(
      false,
      -1,
      null,
    );
  }
}

void moveToLogin() async {
  await AuthUtility.clearUserInfo();
  // ignore: use_build_context_synchronously
  Navigator.pushAndRemoveUntil(
      TaskManagerApp.globalKey.currentState!.context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false);
}
