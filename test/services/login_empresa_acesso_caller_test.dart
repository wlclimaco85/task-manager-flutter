// test/services/login_empresa_acesso_caller_test.dart
//
// Testes com MockClient (package:http/testing.dart) — o backend real
// (Fase 178) ainda esta sendo implementado em paralelo, entao estes testes
// nao batem em API real. A integracao contra o backend real e' validada na
// Task 7 do plano (fora do escopo desta task).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/login_empresa_acesso_caller.dart';

void main() {
  final originalClient = LoginEmpresaAcessoCaller.client;

  tearDown(() {
    LoginEmpresaAcessoCaller.client = originalClient;
  });

  group('LoginEmpresaAcessoCaller.listarMinhasEmpresas', () {
    test('body malformado (nao e Map/List) → retorna lista vazia, nao null',
        () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response('not a json body {{{', 200);
      });

      final result = await LoginEmpresaAcessoCaller.listarMinhasEmpresas();

      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('data nao e uma lista → retorna lista vazia', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response(jsonEncode({'data': 'nao-e-lista'}), 200);
      });

      final result = await LoginEmpresaAcessoCaller.listarMinhasEmpresas();

      expect(result, isEmpty);
    });

    test('status != 200 → retorna lista vazia', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response('erro interno', 500);
      });

      final result = await LoginEmpresaAcessoCaller.listarMinhasEmpresas();

      expect(result, isEmpty);
    });

    test('200 com lista valida → parseia as empresas aprovadas', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {'empresaId': 1, 'nome': 'Empresa A', 'status': 'APROVADO'},
              {'empresaId': 2, 'nome': 'Empresa B', 'status': 'APROVADO'},
            ]
          }),
          200,
        );
      });

      final result = await LoginEmpresaAcessoCaller.listarMinhasEmpresas();

      expect(result, hasLength(2));
      expect(result[0].empresaId, 1);
      expect(result[0].nome, 'Empresa A');
      expect(result[1].empresaId, 2);
    });
  });

  group('LoginEmpresaAcessoCaller.trocarEmpresaAtiva', () {
    test('200 → resultado de sucesso', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        expect(request.method, 'PUT');
        return http.Response('', 200);
      });

      final result = await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(2);

      expect(result.sucesso, isTrue);
      expect(result.mensagemErro, isNull);
    });

    test('403 → resultado de erro com mensagem parseada de response.message',
        () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'response': {'message': 'Acesso a esta empresa nao foi aprovado.'}
          }),
          403,
        );
      });

      final result = await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(99);

      expect(result.sucesso, isFalse);
      expect(result.mensagemErro, 'Acesso a esta empresa nao foi aprovado.');
    });

    test('403 sem body parseavel → mensagem default', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response('', 403);
      });

      final result = await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(99);

      expect(result.sucesso, isFalse);
      expect(result.mensagemErro, isNotNull);
    });

    test('excecao de rede → resultado de erro, nunca propaga excecao',
        () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        throw Exception('falha de rede simulada');
      });

      final result = await LoginEmpresaAcessoCaller.trocarEmpresaAtiva(2);

      expect(result.sucesso, isFalse);
      expect(result.mensagemErro, isNotNull);
    });
  });

  group('LoginEmpresaAcessoCaller.listarPendentes/aprovar/rejeitar', () {
    test('listarPendentes 200 → lista parseada', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 10,
                'loginNome': 'Fulano',
                'loginEmail': 'fulano@teste.com',
                'empresaNome': 'Empresa X',
                'dataCriacao': '2026-08-29T10:00:00',
              }
            ]
          }),
          200,
        );
      });

      final result = await LoginEmpresaAcessoCaller.listarPendentes();

      expect(result, isNotNull);
      expect(result, hasLength(1));
      expect(result!.first.loginNome, 'Fulano');
    });

    test('listarPendentes falha de rede → retorna null (distinto de vazio)',
        () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        throw Exception('falha de rede simulada');
      });

      final result = await LoginEmpresaAcessoCaller.listarPendentes();

      expect(result, isNull);
    });

    test('aprovar 200 → sucesso', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response('', 200);
      });

      final result = await LoginEmpresaAcessoCaller.aprovar(10);

      expect(result.sucesso, isTrue);
    });

    test('rejeitar 404 → conflito (outra pessoa ja decidiu)', () async {
      LoginEmpresaAcessoCaller.client = MockClient((request) async {
        return http.Response('', 404);
      });

      final result = await LoginEmpresaAcessoCaller.rejeitar(10);

      expect(result.sucesso, isFalse);
      expect(result.conflito, isTrue);
    });
  });
}
