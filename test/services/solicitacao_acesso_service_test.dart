// test/services/solicitacao_acesso_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    token = await loginAndGetToken();
  });

  group('Solicitacao de Acesso API', () {
    test('Criar (endpoint publico, sem token) → 201', () async {
      final email = 'qa_solicitacao_${DateTime.now().millisecondsSinceEpoch}@teste.com';
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': 'QA Teste Solicitacao',
          'email': email,
          'cpfCnpj': '99988877766',
          'cpfSolicitante': '12312312300',
          'senha': '123456',
        }),
      );
      expect(res.statusCode, 201,
          reason: 'Criar solicitacao esperado 201, recebido ${res.statusCode}\n${res.body}');
    });

    // Bug de producao corrigido: a checagem de duplicidade usava cpfCnpj
    // (documento da empresa/parceiro de destino, compartilhado por varias
    // pessoas) -- agora usa cpfSolicitante (identidade pessoal), entao o
    // cenario de "duplicada" precisa repetir o MESMO cpfSolicitante, nao
    // so o mesmo cpfCnpj.
    test('Criar duplicada (mesmo email/cpfSolicitante, ainda PENDENTE) → 409', () async {
      final email = 'qa_dup_${DateTime.now().millisecondsSinceEpoch}@teste.com';
      const cpfCnpj = '11122233344';
      const cpfSolicitante = '32132132100';
      final body = jsonEncode({
        'nome': 'QA Dup',
        'email': email,
        'cpfCnpj': cpfCnpj,
        'cpfSolicitante': cpfSolicitante,
        'senha': '123456',
      });

      final primeira = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: body,
      );
      expect(primeira.statusCode, 201, reason: 'Primeira solicitacao deveria criar');

      final segunda = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: body,
      );
      expect(segunda.statusCode, 409,
          reason: 'Duplicada esperado 409, recebido ${segunda.statusCode}\n${segunda.body}');
    });

    // BUG DE PRODUCAO reportado com screenshot: 2 pessoas DIFERENTES
    // (CPFs pessoais distintos) solicitando acesso pra vincular na MESMA
    // empresa/parceiro (mesmo CNPJ) nao podem colidir -- a checagem de
    // duplicidade e por (email, cpfSolicitante), nunca por cpfCnpj (que e
    // compartilhado por design entre varios solicitantes legitimos).
    test('2 solicitantes DIFERENTES para o MESMO cnpj (empresa/parceiro) → ambos 201, sem 409',
        () async {
      final cnpjCompartilhado = '19364209${DateTime.now().millisecondsSinceEpoch % 1000000}'
          .padRight(14, '0')
          .substring(0, 14);

      final primeiraPessoa = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': 'QA Pessoa Um',
          'email': 'qa_pessoa1_${DateTime.now().millisecondsSinceEpoch}@teste.com',
          'cpfCnpj': cnpjCompartilhado,
          'cpfSolicitante': '11111111111',
          'senha': '123456',
        }),
      );
      expect(primeiraPessoa.statusCode, 201,
          reason: 'Primeiro solicitante deveria criar, recebido ${primeiraPessoa.statusCode}\n${primeiraPessoa.body}');

      final segundaPessoa = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': 'QA Pessoa Dois',
          'email': 'qa_pessoa2_${DateTime.now().millisecondsSinceEpoch}@teste.com',
          'cpfCnpj': cnpjCompartilhado, // MESMO cnpj da empresa/parceiro
          'cpfSolicitante': '22222222222', // CPF pessoal DIFERENTE
          'senha': '123456',
        }),
      );
      expect(segundaPessoa.statusCode, 201,
          reason: 'Segundo solicitante (mesmo cnpj, cpf pessoal diferente) '
              'nao deveria ser bloqueado como duplicata -- recebido '
              '${segundaPessoa.statusCode}\n${segundaPessoa.body}');
    });

    test('Listar pendentes (autenticado) → 200', () async {
      final res = await http.get(
        Uri.parse(ApiLinks.solicitacaoAcessoPendentes),
        headers: authHeaders(token),
      );
      expectListOk(res.statusCode, 'Listar Pendentes');

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      expect(decoded['data'], isA<List>(),
          reason: 'Resposta deveria conter data como lista');
    });

    test('Aprovar solicitacao inexistente → 404', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcessoAprovar(999999999)),
        headers: authHeaders(token),
      );
      expect(res.statusCode, 404,
          reason: 'Aprovar id inexistente esperado 404, recebido ${res.statusCode}');
    });

    test('Rejeitar solicitacao inexistente → 404', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcessoRejeitar(999999999)),
        headers: authHeaders(token),
      );
      expect(res.statusCode, 404,
          reason: 'Rejeitar id inexistente esperado 404, recebido ${res.statusCode}');
    });
  });
}
