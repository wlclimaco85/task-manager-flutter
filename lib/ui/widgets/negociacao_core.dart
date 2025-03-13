import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';

class RenegotiationHandler {
  static Future<bool> renegotiate({
    required BuildContext context,
    required int vendaId,
    required int compradorId,
    required int vendedorId,
    required int qtdSacos,
    required double vlrSacos,
    required int qtdDisponivel,
    required int negociacaoId,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (qtdSacos > qtdDisponivel) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message:
              "A quantidade de sacos solicitada ($qtdSacos) excede o disponível ($qtdDisponivel).",
          isError: true,
        );
        return false;
      }

      if (vlrSacos <= 0) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message: "O valor por saco deve ser maior que zero.",
          isError: true,
        );
        return false;
      }

      Map<String, dynamic> requestBody = {
        "vendaId": vendaId,
        "compradorId": compradorId,
        "vendedorId": vendedorId,
        "qtdSacos": qtdSacos,
        "vlrSacos": vlrSacos,
        "negociacaoId": negociacaoId,
      };

      // Substitua NetworkCaller e ApiLinks por suas implementações reais
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertNegociacao, requestBody);

      Navigator.of(context).pop();

      if (response.isSuccess) {
        _showSnackBar(
          context,
          message: "Proposta enviada com sucesso!",
          isError: false,
        );
        return true;
      } else {
        _showSnackBar(
          context,
          message: "Erro ao enviar proposta.",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar(
        context,
        message: "Erro: ${e.toString()}",
        isError: true,
      );
      return false;
    }
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
