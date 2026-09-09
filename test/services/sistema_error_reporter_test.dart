import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/sistema_error_reporter.dart';

void main() {
  test('SistemaErrorReporter enfileira e envia erro para o endpoint', () async {
    final requisicoes = <http.Request>[];

    final client = MockClient((request) async {
      requisicoes.add(request);
      return http.Response(jsonEncode({'id': 1}), 200);
    });

    final reporter = SistemaErrorReporter.instance;
    reporter.setClient(client);

    reporter.reportarErro(
      mensagem: 'Teste de excecao controlada',
      detalhes: 'stacktrace fake',
      classeOuRota: 'TesteUnitario',
      nivel: 'ERROR',
    );

    await reporter.flushBuffer();

    expect(requisicoes.length, 1);
    final req = requisicoes.first;
    expect(req.url.path, contains('/api/sistema-logs'));
    final body = jsonDecode(req.body) as Map<String, dynamic>;
    expect(body['mensagem'], 'Teste de excecao controlada');
    expect(body['origem'], 'APP_FLUTTER');
    expect(body['nivel'], 'ERROR');
  });
}
