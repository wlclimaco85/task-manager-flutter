import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/app.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';

class NetworkCaller {
  Future<NetworkResponse> getRequest(String url) async {
    try {
      final login = AuthUtility.userInfo?.login;
      final user = AuthUtility.userInfo?.data;
      // Adiciona empresa, parceiro e aplicativo como query params
      Uri uri = Uri.parse(url).replace(
        queryParameters: {
          ...Uri.parse(url).queryParameters, // mantém query existentes
          'empresa': login?.empresa?.id?.toString() ?? '',
          'parceiro': login?.parceiro?.id?.toString() ?? '',
          'aplicativo': login?.aplicativo?.id?.toString() ?? '',
          'audit.parceiroId': login?.parceiro?.id?.toString() ?? '',
          'audit.empresaId': login?.empresa?.id?.toString() ?? '',
          'audit.appId': login?.aplicativo?.id?.toString() ?? '',
          'audit.userLogadoId': login?.id?.toString() ?? '',
        },
      );

      Response response = await get(
        uri,
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          'Accept-Encoding': 'gzip',
        },
      );
      if (response.statusCode == 200) {
        return NetworkResponse(
          true,
          response.statusCode,
          jsonDecode(response.body),
        );
      } else if (AuthUtility.userInfo?.data?.id == null ||
          AuthUtility.userInfo?.data?.id == 1 && response.statusCode == 403) {
        loginPadrao();
        Response response = await get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer ${AuthUtility.userInfo?.token}'},
        );
        if (response.statusCode == 200) {
          return NetworkResponse(
            true,
            response.statusCode,
            jsonDecode(response.body),
          );
        } else {
          return NetworkResponse(false, response.statusCode, null);
        }
      } else {
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(false, -1, null);
  }

  Future<NetworkResponse> getRequests(String url, BuildContext context) async {
    try {
      final user = AuthUtility.userInfo?.data;

      // Adiciona empresa, parceiro e aplicativo como query params
      Uri uri = Uri.parse(url).replace(
        queryParameters: {
          ...Uri.parse(url).queryParameters, // mantém query existentes
          'empresa': {'id': user?.login?.empresa?.id?.toString()},
          'parceiro': {'id': user?.login?.parceiro?.id?.toString()},
          'aplicativo': {'id': user?.login?.aplicativo?.id?.toString()},
        },
      );
      if (AuthUtility.userInfo?.data?.id != 1) {
        Response response = await get(
          uri,
          headers: {'Authorization': 'Bearer ${AuthUtility.userInfo?.token}'},
        );
        if (response.statusCode == 200) {
          return NetworkResponse(
            true,
            response.statusCode,
            jsonDecode(response.body),
          );
        } else if (response.statusCode == 403) {
          // Mostrar LoginPopup
          final result = await showDialog(
            context: context,
            builder: (BuildContext context) => const LoginPopup(),
          );

          if (result == true) {
            // Tenta novamente após login bem-sucedido
            if (AuthUtility.userInfo?.data?.id != 1) {
              Response response = await get(
                Uri.parse(url),
                headers: {
                  'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
                },
              );
              if (response.statusCode == 200) {
                return NetworkResponse(
                  true,
                  response.statusCode,
                  jsonDecode(response.body),
                );
              } else {
                return NetworkResponse(false, response.statusCode, null);
              }
            }
          }
        } else {
          return NetworkResponse(false, response.statusCode, null);
        }
      } else {
        // Mostrar LoginPopup
        final result = await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );

        if (result == true) {
          // Tenta novamente após login bem-sucedido
          if (AuthUtility.userInfo?.data?.id != 1) {
            Response response = await get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
              },
            );
            if (response.statusCode == 200) {
              return NetworkResponse(
                true,
                response.statusCode,
                jsonDecode(response.body),
              );
            } else {
              return NetworkResponse(false, response.statusCode, null);
            }
          }
        }
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(false, -1, null);
  }

  Future<void> loginPadrao() async {
    Map<String, dynamic> requestBody = {
      "email": 'wlclimaco@gmail.com',
      "password": '123456',
    };
    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.login,
      requestBody,
    );

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

  Future<NetworkResponse> postRequest(
    String url,
    Map<String, dynamic>? body,
  ) async {
    try {
      final user = AuthUtility.userInfo?.login;

      // Adiciona empresa, parceiro e aplicativo ao body
      body?['empresa'] = {};
      body?['parceiro'] = {};
      body?['aplicativo'] = {};
      body?['audit'] = {};
      body?['empresa']['id'] = user?.empresa?.id ?? null;
      body?['parceiro']['id'] = user?.parceiro?.id ?? null;
      body?['aplicativo']['id'] = user?.aplicativo != null
          ? user?.aplicativo?.id
          : null;
      body?['audit']['parceiroId'] = user?.parceiro?.id ?? null;
      body?['audit']['empresaId'] = user?.empresa?.id ?? null;
      body?['audit']['appId'] = user?.aplicativo?.id ?? null;
      body?['audit']['userLogadoId'] = user?.id ?? null;

      Response response = await post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          //TODO     'Authorization': url.contains('login') || url.contains('inserirAluno')
          'Authorization': url.contains('inserirAluno')
              ? 'c2Fua2h5YTpzdXA='
              : 'Bearer ${AuthUtility.userInfo?.token}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
        body: jsonEncode(body),
      );

      print('POST $url');
      print('Request Body: ${jsonEncode(body)}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
          true,
          response.statusCode,
          jsonDecode(response.body),
        );
      } else {
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      log(e.toString());
    }
    return NetworkResponse(false, -1, null);
  }

  Future<NetworkResponse> deleteRequest(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final user = AuthUtility.userInfo?.login;

      // Se queryParams é nulo, cria um novo Map, senão usa o passado
      queryParams ??= {};

      // Adiciona os parâmetros padrão
      queryParams['empresaId'] = user?.empresa?.id ?? 1;
      queryParams['parceiroId'] = user?.parceiro?.id ?? 1;
      queryParams['appId'] = user?.aplicativo?.id ?? 1;
      queryParams['userLogadoId'] = user?.id ?? 1;

      // Constrói a URI com os query parameters
      Uri uri = Uri.parse(url);
      uri = uri.replace(queryParameters: queryParams);

      final response = await delete(
        uri,
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, DELETE',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
      );

      print('DELETE $uri');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Se a resposta for bem-sucedida e tiver corpo, decodifica, senão retorna null
        final body = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return NetworkResponse(true, response.statusCode, body);
      } else {
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      log(e.toString());
      return NetworkResponse(false, -1, null);
    }
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
