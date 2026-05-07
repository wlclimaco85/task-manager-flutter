// test/services/comunicado_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async {
    token = await loginAndGetToken();
  });

  group('Comunicados API', () {
    test('Listar → 200', () async {
      final res = await http.get(
        Uri.parse(ApiLinks.allComunicados),
        headers: authHeaders(token),
      );
      expectListOk(res.statusCode, 'Listar Comunicados');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createComunicado),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'titulo': 'Comunicado Teste',
          'descricao': 'Gerado por teste automatizado',
          'ativo': true,
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Comunicado');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateComunicado(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'titulo': 'Comunicado Atualizado', 'ativo': true})),
      );
      expectUpdateOk(res.statusCode, 'Update Comunicado');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(
        Uri.parse(ApiLinks.deleteComunicado(createdId.toString())),
        headers: authHeaders(token),
      );
      expectDeleteOk(res.statusCode, 'Delete Comunicado');
    });
  });
}
