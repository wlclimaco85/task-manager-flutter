import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

class NfseXmlImportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;

  NfseXmlImportResult({required this.success, this.data, this.message});
}

/// Chamadas REST da importacao de XML de NFS-e -- analogo a
/// NfeXmlImportCaller (importacao de NF-e), mesmo contrato preview/confirmar.
/// Diferente daquele, usa o campo multipart "xml" (nome exigido pelo
/// NfseImportController: @RequestParam("xml")).
class NfseXmlImportCaller {
  static Future<NfseXmlImportResult> preview(String filePath) async {
    return _enviarXml(ApiLinks.nfseImportacaoPreview, filePath);
  }

  static Future<NfseXmlImportResult> confirmar(
    String filePath, {
    int? produtoId,
    bool criarNovoProduto = false,
  }) async {
    Map<String, String>? campos;
    if (produtoId != null || criarNovoProduto) {
      campos = {
        'conciliacao': jsonEncode({
          if (produtoId != null) 'produtoId': produtoId,
          'criarNovoProduto': criarNovoProduto,
        }),
      };
    }
    return _enviarXml(ApiLinks.nfseImportacaoConfirmar, filePath, campos: campos);
  }

  static Future<NfseXmlImportResult> _enviarXml(
    String endpoint,
    String filePath, {
    Map<String, String>? campos,
  }) async {
    try {
      final uri = TenantContext.applyToUrl(endpoint);
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(uri));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (campos != null) {
        request.fields.addAll(campos);
      }

      final bytes = await File(filePath).readAsBytes();
      final fileName = filePath.split(Platform.pathSeparator).last;
      request.files.add(http.MultipartFile.fromBytes(
        'xml',
        bytes,
        filename: fileName,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        return NfseXmlImportResult(
          success: true,
          data: body is Map<String, dynamic> ? body : {'data': body},
        );
      }

      String msg = 'Erro na importacao de XML NFS-e (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      AppLogger.i.warn('NfseXmlImportCaller: falha em $endpoint (${resp.statusCode}): $msg');
      return NfseXmlImportResult(success: false, message: msg);
    } catch (e, st) {
      AppLogger.i.error('NfseXmlImportCaller: erro ao chamar $endpoint', st);
      return NfseXmlImportResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<List<dynamic>> listar() async {
    try {
      final uri = TenantContext.applyToUrl(ApiLinks.nfseImportacaoListar);
      final token = AuthUtility.userInfo?.token;

      final resp = await http.get(
        Uri.parse(uri),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : [];
        if (body is List) return body;
        if (body is Map && body['content'] is List) return body['content'] as List;
        if (body is Map && body['data'] is List) return body['data'] as List;
      }
      AppLogger.i.warn('NfseXmlImportCaller.listar: resposta inesperada (${resp.statusCode})');
      return [];
    } catch (e, st) {
      AppLogger.i.error('NfseXmlImportCaller.listar: erro ao conectar', st);
      return [];
    }
  }
}
