import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NfeXmlImportResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? message;

  NfeXmlImportResult({required this.success, this.data, this.message});
}

class NfeXmlImportCaller {
  static Future<NfeXmlImportResult> preview(String filePath) async {
    try {
      final uri = TenantContext.applyToUrl(ApiLinks.nfeImportacaoPreview);
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(uri));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final bytes = await File(filePath).readAsBytes();
      final fileName = filePath.split(Platform.pathSeparator).last;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        return NfeXmlImportResult(
          success: true,
          data: body is Map<String, dynamic> ? body : {'data': body},
        );
      }

      String msg = 'Erro no preview (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return NfeXmlImportResult(success: false, message: msg);
    } catch (e) {
      return NfeXmlImportResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<NfeXmlImportResult> confirmar(String filePath) async {
    try {
      final uri = TenantContext.applyToUrl(ApiLinks.nfeImportacaoConfirmar);
      final token = AuthUtility.userInfo?.token;

      final request = http.MultipartRequest('POST', Uri.parse(uri));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final bytes = await File(filePath).readAsBytes();
      final fileName = filePath.split(Platform.pathSeparator).last;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
        return NfeXmlImportResult(
          success: true,
          data: body is Map<String, dynamic> ? body : {'data': body},
        );
      }

      String msg = 'Erro na importação (${resp.statusCode})';
      try {
        final body = jsonDecode(resp.body);
        msg = body['mensagem']?.toString() ??
            body['message']?.toString() ??
            body['error']?.toString() ??
            msg;
      } catch (_) {}
      return NfeXmlImportResult(success: false, message: msg);
    } catch (e) {
      return NfeXmlImportResult(success: false, message: 'Erro ao conectar: $e');
    }
  }

  static Future<List<dynamic>> listar() async {
    try {
      final uri = TenantContext.applyToUrl(ApiLinks.nfeImportacaoListar);
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
        if (body is Map && body.containsKey('data')) return body['data'] as List;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
