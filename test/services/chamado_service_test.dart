// test/services/chamado_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Chamados API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allChamados), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Chamados');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createChamado),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'titulo': 'Chamado Teste',
          'descricao': 'Gerado por teste automatizado',
          'status': 'ABERTO',
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Chamado');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateChamado(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'titulo': 'Chamado Atualizado', 'status': 'EM_ANDAMENTO'})),
      );
      expectUpdateOk(res.statusCode, 'Update Chamado');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteChamado(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Chamado');
    });
  });
}
