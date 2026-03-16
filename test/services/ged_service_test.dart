// test/services/ged_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Documentos - Listagem', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.fecthAllDocumentos), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Documentos');
    });
  });

  group('Diretórios API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allDiretorios), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Diretórios');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createDiretorio),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Diretório Teste', 'descricao': 'Gerado por teste'})),
      );
      expectInsertOk(res.statusCode, 'Insert Diretório');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateDiretorio(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Diretório Atualizado'})),
      );
      expectUpdateOk(res.statusCode, 'Update Diretório');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteDiretorio(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Diretório');
    });
  });

  group('Arquivos API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allArquivos), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Arquivos');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createArquivo),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'arquivo_teste.txt', 'tipo': 'text/plain'})),
      );
      expectInsertOk(res.statusCode, 'Insert Arquivo');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateArquivo(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'arquivo_atualizado.txt'})),
      );
      expectUpdateOk(res.statusCode, 'Update Arquivo');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteArquivo(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Arquivo');
    });
  });
}
