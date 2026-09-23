import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/solicitacao_acesso_aprovacao_screen.dart';

void main() {
  testWidgets(
      'aprova cliente somente depois do passo a passo com destino e role fixa',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var aprovacaoEnviada = false;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 91,
                'nome': 'Maria Cliente',
                'email': 'maria@cliente.com.br',
                'cpfCnpj': '38504938000111',
                'cpfSolicitante': '12345678901',
                'status': 'PENDENTE',
                'parceiroIdResolvido': 1805,
                'parceiroNomeResolvido': 'Abraco Contabilidade',
                'empresaIdResolvida': 1,
                'empresaNomeResolvida': 'Empresa Smoke Test',
                'dataCriacao': '2026-09-23T09:30:00'
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/solicitacao-acesso/91/aprovar')) {
        aprovacaoEnviada = true;
        return http.Response('{}', 200);
      }
      return http.Response('Nao esperado', 500);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: SolicitacaoAcessoAprovacaoScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Abraco Contabilidade'), findsOneWidget);
      await tester.tap(find.byTooltip('Aprovar'));
      await tester.pumpAndSettle();

      expect(find.text('Revisar solicitacao'), findsOneWidget);
      expect(find.text('Perfil de acesso'), findsOneWidget);
      expect(find.text('CLIENTE'), findsOneWidget);
      expect(find.text('Abraco Contabilidade'), findsWidgets);
      expect(aprovacaoEnviada, isFalse);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar aprovacao'), findsOneWidget);
      expect(find.text('Aprovar cliente'), findsOneWidget);
      expect(aprovacaoEnviada, isFalse);

      await tester.tap(find.text('Aprovar cliente'));
      await tester.pumpAndSettle();

      expect(aprovacaoEnviada, isTrue);
      expect(find.text('Maria Cliente'), findsNothing);
    }, () => client);
  });
}
