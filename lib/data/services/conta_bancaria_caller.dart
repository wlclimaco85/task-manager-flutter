import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'dart:typed_data';
import '../models/conta_Bancaria_model.dart';
import 'package:flutter/material.dart';

class ContaBancariaCaller {
  Future<List<ContaBancaria>> fetchContas(BuildContext context) async {
    List<ContaBancaria> contas = [];

    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.contasBancarias);

      if (response.isSuccess && response.body != null) {
        final List<dynamic> data = response.body!['data']['dados'] ?? [];
        contas = data
            .map((item) =>
                ContaBancaria.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao buscar contas bancárias: $e');
    }

    return contas;
  }

  Future<bool> ativarConta(int id, bool ativo) async {
    try {
      final url = '${ApiLinks.contasBancarias}/$id/ativar?ativo=$ativo';
      final NetworkResponse response = await NetworkCaller().getRequest(url);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao ativar/desativar conta: $e');
      return false;
    }
  }

  /// 💸 Realiza transferência entre contas
  Future<bool> transferirSaldo({
    required int contaOrigemId,
    required int contaDestinoId,
    required double valor,
    required int empresaId,
    int? parceiroId,
    String? historico,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/transferir'
          '?contaOrigemId=$contaOrigemId'
          '&contaDestinoId=$contaDestinoId'
          '&valor=$valor'
          '&empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}'
          '${historico != null && historico.isNotEmpty ? '&historico=$historico' : ''}';

      final NetworkResponse response =
          await NetworkCaller().postRequest(url, {});
      return response.isSuccess;
    } catch (e) {
      debugPrint('Erro ao transferir saldo: $e');
      return false;
    }
  }

  Future<Uint8List?> gerarExtratoPdf({
    required int contaId,
    required int empresaId,
    int? parceiroId,
    required String de,
    required String ate,
  }) async {
    try {
      final url = '${ApiLinks.contasBancarias}/extrato/pdf'
          '?contaId=$contaId'
          '&empresaId=$empresaId'
          '${parceiroId != null ? '&parceiroId=$parceiroId' : ''}'
          '&de=$de'
          '&ate=$ate';

      final response = await NetworkCaller().getRawBytes(url);
      return response; // bytes do PDF
    } catch (e) {
      debugPrint('Erro ao gerar extrato PDF: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> loadContas() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.contasBancarias);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => {
                'value': item['id'],
                'label': '${item['banco'] ?? ''} - ${item['numero'] ?? ''}',
              })
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadContas2() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allContasBancarias);
    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map((item) => {
                'value': item['id'],
                'label':
                    '${item['banco'] ?? ''} - ${item['numero'] ?? ''} (${item['descricao'] ?? ''})',
              })
          .toList();
    }
    return [];
  }
}
