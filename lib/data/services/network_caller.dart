import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';
import 'package:task_manager_flutter/data/models/login_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkCaller {
  Future<NetworkResponse> getRequest(String url) async {
    try {
      Response response = await get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo.token}',
          'Accept-Encoding': 'gzip'
        },
      );
      if (response.statusCode == 200) {
        return NetworkResponse(
            true, response.statusCode, jsonDecode(response.body));
      } else if (AuthUtility.userInfo.data?.id == null ||
          AuthUtility.userInfo.data?.id == 1 && response.statusCode == 403) {
        loginPadrao();
        Response response = await get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthUtility.userInfo.token}'},
        );
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

  Future<NetworkResponse> getRequests(String url, BuildContext context) async {
    try {
      if (AuthUtility.userInfo.data?.id != 1) {
        Response response = await get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthUtility.userInfo.token}'},
        );
        if (response.statusCode == 200) {
          return NetworkResponse(
              true, response.statusCode, jsonDecode(response.body));
        } else if (response.statusCode == 403) {
          // Mostrar LoginPopup
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) => const LoginPopup(),
          );

          if (result == true) {
            // Tenta novamente após login bem-sucedido
            if (AuthUtility.userInfo.data?.id != 1) {
              Response response = await get(
                Uri.parse(url),
                headers: {
                  'Authorization': 'Bearer ${AuthUtility.userInfo.token}'
                },
              );
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
            }
          }
        } else {
          return NetworkResponse(
            false,
            response.statusCode,
            null,
          );
        }
      } else {
        // Mostrar LoginPopup
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );

        if (result == true) {
          // Tenta novamente após login bem-sucedido
          if (AuthUtility.userInfo.data?.id != 1) {
            Response response = await get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer ${AuthUtility.userInfo.token}'
              },
            );
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
          }
        }
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

  Future<void> loginPadrao() async {
    Map<String, dynamic> requestBody = {
      "email": 'wlclimaco@gmail.com',
      "password": '123456'
    };
    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.login, requestBody);

    if (response.isSuccess) {
      LoginModel model = LoginModel.fromJson(response.body!);
      await AuthUtility.setUserInfo(model);
    } else {
      if (response.statusCode == 400) {
        print('Senha ou usuário inválido');
      } else {
        print('Erro: ${response.statusCode}');
      }
    }
  }

  Future<NetworkResponse> deleteRequest(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': url.contains('login') || url.contains('inserirAluno')
              ? 'c2Fua2h5YTpzdXA='
              : 'Bearer ${AuthUtility.userInfo.token}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content é comum em DELETE
        return NetworkResponse(
          true,
          response.statusCode,
          response.body.isNotEmpty ? jsonDecode(response.body) : null,
        );
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

  Future<NetworkResponse> putRequest(
    String url,
    Map<String, dynamic>? body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': url.contains('login') || url.contains('inserirAluno')
              ? 'c2Fua2h5YTpzdXA='
              : 'Bearer ${AuthUtility.userInfo.token}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
          true,
          response.statusCode,
          jsonDecode(response.body),
        );
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
      Response response = await post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
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
  Navigator.pushAndRemoveUntil(
    TaskManagerApp.globalKey.currentState!.context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}
