import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';

import '../models/ponto_model.dart';

class PontoCaller {
  ///
  /// 🔥 REGISTRAR ENTRADA/SAÍDA AUTOMÁTICA
  ///
  Future<PontoModel?> registrarPonto(
    BuildContext context, {
    required int parceiroId,
    required TipoRegistro tipo,
    String? observacao,
  }) async {
    try {
      // se o usuário precisar relogar
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo?.data?.id == 1) {
        await showDialog(
          context: context,
          builder: (_) => const LoginPopup(),
        );
      }

      final Map<String, dynamic> body = {
        "parceiroId": parceiroId,
        "tipo": tipo.apiValue,
        if (observacao != null && observacao.isNotEmpty)
          "observacao": observacao,
      };

      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.pontoRegistrar,
        body,
      );

      if (response.statusCode == 200 && response.body != null) {
        return PontoModel.fromJson(response.body!);
      }

      return null;
    } catch (e) {
      print("❌ Erro registrar ponto: $e");
      return null;
    }
  }

  ///
  /// 🔥 LISTAR MARCAÇÕES DO DIA
  ///
  Future<List<PontoModel>> listarPorDia({
    required int parceiroId,
    required DateTime data,
  }) async {
    try {
      final String d = data.toIso8601String().split("T")[0];

      final NetworkResponse response = await NetworkCaller().getRequest(
        "${ApiLinks.pontoListar}/$parceiroId?data=$d",
      );

      if (response.statusCode == 200 && response.body != null) {
        final List lista = response.body as List;
        return lista.map((e) => PontoModel.fromJson(e)).toList();
      }

      return [];
    } catch (e) {
      print("❌ Erro ao listar pontos: $e");
      return [];
    }
  }

  ///
  /// 🔥 CALCULAR BANCO DE HORAS
  ///
  Future<double> calcularBancoHoras({
    required int parceiroId,
    required DateTime mes,
  }) async {
    try {
      final mesStr = mes.toIso8601String().split("T")[0];

      final NetworkResponse response = await NetworkCaller().getRequest(
        "${ApiLinks.pontoBancoHoras}/$parceiroId?mesReferencia=$mesStr",
      );

      if (response.statusCode == 200 && response.body != null) {
        return double.tryParse(response.body.toString()) ?? 0;
      }

      return 0;
    } catch (e) {
      print("❌ Erro calcular banco: $e");
      return 0;
    }
  }

  ///
  /// 🔥 GERAR PDF (HTTP + TOKEN)
  ///
  Future<Uint8List?> gerarPdf({
    required int parceiroId,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    try {
      final i = inicio.toIso8601String().split("T")[0];
      final f = fim.toIso8601String().split("T")[0];
      // TOKEN IGUAL AO NETWORKCALLER
      // If you have a token available in AuthUtility, replace the null assignment below
      // with the appropriate accessor (e.g. AuthUtility.userInfo?.data?.token).
      final String? token = AuthUtility.userInfo?.token;

      final uri = Uri.parse(
        "${ApiLinks.pontoPdf}/$parceiroId?inicio=$i&fim=$f",
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return response.bodyBytes; // PDF
      }

      print("❌ Erro PDF status: ${response.statusCode}");
      return null;
    } catch (e) {
      print("❌ Erro gerar PDF: $e");
      return null;
    }
  }
}
