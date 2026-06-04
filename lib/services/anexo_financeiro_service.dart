import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../models/anexo_financeiro_model.dart';
import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

const int _maxBytes = 10 * 1024 * 1024; // 10MB
const List<String> _allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'xml'];
const List<String> _allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'application/xml', 'text/xml'];

class AnexoFinanceiroService {
  Future<List<AnexoFinanceiro>> listar(int lancamentoId, String tipo) async {
    final uri = Uri.parse(
      TenantContext.applyToUrl(ApiLinks.anexosFinanceiros) +
          '&lancamentoId=$lancamentoId&tipo=$tipo',
    );
    final resp = await http.get(uri, headers: TenantContext.jsonHeaders);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return list.map((e) => AnexoFinanceiro.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw AnexoException('Erro ao listar anexos (${resp.statusCode})');
  }

  Future<AnexoFinanceiro> upload(int lancamentoId, String tipo, PlatformFile file) async {
    _validarArquivo(file);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexosFinanceiros)),
    );
    request.headers.addAll(TenantContext.headers);
    request.fields['lancamentoId'] = lancamentoId.toString();
    request.fields['tipo'] = tipo;

    final bytes = file.bytes ?? (file.path != null ? await _readFile(file.path!) : null);
    if (bytes == null) throw const AnexoException('Não foi possível ler o arquivo');

    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 200 || streamed.statusCode == 201) {
      return AnexoFinanceiro.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw AnexoException('Erro ao enviar anexo (${streamed.statusCode})');
  }

  Future<Uint8List> download(int id) async {
    final token = AuthUtility.userInfo?.token;
    final resp = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexoFinanceiroDownload(id.toString()))),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode == 200) return resp.bodyBytes;
    throw AnexoException('Erro ao baixar anexo (${resp.statusCode})');
  }

  Future<void> remover(int id) async {
    final resp = await http.delete(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.anexoFinanceiro(id.toString()))),
      headers: TenantContext.headers,
    );
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw AnexoException('Erro ao remover anexo (${resp.statusCode})');
    }
  }

  void _validarArquivo(PlatformFile file) {
    final ext = file.name.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw AnexoException('Tipo não aceito: .$ext. Use: ${_allowedExtensions.join(', ')}');
    }
    final size = file.size;
    if (size > _maxBytes) {
      throw AnexoException('Arquivo muito grande (${(size / (1024 * 1024)).toStringAsFixed(1)}MB). Máximo: 5MB');
    }
  }

  Future<Uint8List> _readFile(String path) async {
    final f = await http.get(Uri.file(path));
    return f.bodyBytes;
  }
}

class AnexoException implements Exception {
  final String message;
  const AnexoException(this.message);
  @override
  String toString() => message;
}
