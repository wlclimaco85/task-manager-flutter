import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../models/network_response.dart';
import '../../mobile/screens/LoginPopup_screens.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../models/login_model.dart';
import '../../../utils/app_logger.dart';


class NetworkCaller {
  Future<NetworkResponse> getRequest(String url) async {
    try {
      final enrichedUrl = TenantContext.applyToUrl(url);
      final uri = Uri.parse(enrichedUrl);

      AppLogger.i.info(
          '⚙️ [GET] tenant=${TenantContext.debugInfo} | url=${uri.toString()}');

      Response response = await get(
        uri,
        headers: {
          if (AuthUtility.userInfo?.token != null)
            'Authorization': 'Bearer ${AuthUtility.userInfo!.token}',
          'Accept-Encoding': 'gzip',
        },
      );

      AppLogger.i.info(
          '⚙️ [GET] url : ${uri.toString()} | statusCode: ${response.statusCode}');      if (response.statusCode == 200) {
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
        L.d('Senha ou usuário inválido');
      } else {
        L.d('Erro: ${response.statusCode}');
      }
    }
  }

  Future<NetworkResponse> putRequest(String url, dynamic body) async {
    try {
      final enrichedUrl = TenantContext.applyToUrl(url);
      final response = await put(
        Uri.parse(enrichedUrl),
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
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
    } catch (e) {
      debugPrint('Error in PUT request: $e');
      return NetworkResponse(false, 500, {'error': 'Network error: $e'});
    }
  }

  Future<NetworkResponse> patchRequest(String url, dynamic body) async {
    try {
      final enrichedUrl = TenantContext.applyToUrl(url);
      final response = await patch(
        Uri.parse(enrichedUrl),
        headers: {
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
          'Accept-Encoding': 'gzip',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        return NetworkResponse(
          true,
          response.statusCode,
          responseBody,
        );
      } else {
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e) {
      debugPrint('Error in PATCH request: $e');
      return NetworkResponse(false, 500, {'error': 'Network error: $e'});
    }
  }

  Future<NetworkResponse> postRequest(
    String url,
    Map<String, dynamic>? body,
  ) async {
    try {
      final user = AuthUtility.userInfo?.login;

      // Não adiciona campos extras para login/auth endpoints
      final bool isAuthRequest =
          url.contains('login') || url.contains('inserirAluno');

      if (!isAuthRequest && body != null) {
        // Usa TenantContext para injetar empresa/parceiro/aplicativo no body
        body = TenantContext.applyToBody(body);
        // Garante audit no body
        body['audit'] ??= {};
        body['audit']['empresaId'] = user?.empresa?.id;
        body['audit']['appId'] = user?.aplicativo?.id;
        body['audit']['userLogadoId'] = user?.id;
        if (user?.parceiro?.id != null) {
          body['audit']['parceiroId'] = user!.parceiro!.id;
        }
      }

      // Injeta tenant params na URL também (para controllers que lêem da query)
      final enrichedUrl = isAuthRequest ? url : TenantContext.applyToUrl(url);

      AppLogger.i.info('📤 [POST] url=$enrichedUrl | body=${jsonEncode(body)}');

      Response response = await post(
        Uri.parse(enrichedUrl),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': isAuthRequest
              ? 'c2Fua2h5YTpzdXA='
              : 'Bearer ${AuthUtility.userInfo?.token}',
        },
        body: jsonEncode(body),
      );

      AppLogger.i.info(
          '📥 [POST] status=${response.statusCode} | body=${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetworkResponse(
          true,
          response.statusCode,
          jsonDecode(response.body),
        );
      } else {
        return NetworkResponse(false, response.statusCode, null);
      }
    } catch (e, stack) {
      log('💥 [POST] Erro: $e\n$stack');
    }
    return NetworkResponse(false, -1, null);
  }

  Future<NetworkResponse> deleteRequest(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      // Injeta tenant params via TenantContext
      final enrichedUrl = TenantContext.applyToUrl(url);
      Uri uri = Uri.parse(enrichedUrl);

      // Adiciona queryParams extras se fornecidos
      if (queryParams != null && queryParams.isNotEmpty) {
        final merged = Map<String, String>.from(uri.queryParameters);
        queryParams.forEach((k, v) { if (v != null) merged[k] = v.toString(); });
        uri = uri.replace(queryParameters: merged);
      }

      final response = await delete(
        uri,
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': 'Bearer ${AuthUtility.userInfo?.token}',
        },
      );

      AppLogger.i.info('🗑️ [DELETE] $uri | status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final body =
            response.body.isNotEmpty ? jsonDecode(response.body) : null;
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
