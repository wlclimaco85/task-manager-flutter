import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/solicitacao_acesso_aprovacao_screen.dart';

void main() {
  testWidgets(
      'cenario real: MASTER visualiza e aprova solicitacao pendente com parceiro resolvido',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var aprovacaoEnviada = false;
    List<dynamic>? setoresEnviados;

    // Simula a resposta do backend exatamente como registrado no banco (id=19):
    // parceiroIdResolvido=1761, empresaIdResolvida=null
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/api/setor')) {
        return http.Response(
          jsonEncode({
            'data': {
              'dados': [
                {'id': 7, 'descricao': 'Atendimento'},
                {'id': 8, 'descricao': 'Fiscal'}
              ]
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path.contains('/api/solicitacao-acesso/pendentes')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 19,
                'nome': 'Washington luis',
                'email': 'wlclimacooooo@gmail.com',
                'cpfCnpj': '55364702000146',
                'cpfSolicitante': '05899966655',
                'status': 'PENDENTE',
                'parceiroIdResolvido': 1761,
                'parceiroNomeResolvido': 'EMPRESA PARCEIRA DO ESCRITORIO',
                'empresaIdResolvida': null,
                'empresaNomeResolvida': null,
                'dataCriacao': '2026-09-23T17:01:13'
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path.contains('/solicitacao-acesso/19/aprovar')) {
        aprovacaoEnviada = true;
        setoresEnviados = (jsonDecode(request.body)
            as Map<String, dynamic>)['setorIds'] as List<dynamic>;
        return http.Response(
          jsonEncode({
            'data': {},
            'response': {'status': 200, 'message': 'Aprovado', 'error': false}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: SolicitacaoAcessoAprovacaoScreen(),
      ));
      await tester.pumpAndSettle();

      // Prova que a solicitacao 19 com parceiro resolvido e empresa null APARECE na tela
      expect(find.text('Washington luis'), findsOneWidget);
      expect(find.text('wlclimacooooo@gmail.com'), findsOneWidget);
      expect(find.text('EMPRESA PARCEIRA DO ESCRITORIO'), findsOneWidget);

      // Clica em aprovar
      await tester.tap(find.byTooltip('Aprovar'));
      await tester.pumpAndSettle();

      // Wizard de aprovacao
      expect(find.text('Revisar solicitacao'), findsOneWidget);
      expect(find.text('CLIENTE'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Selecao de setores
      expect(find.text('Selecionar setores'), findsOneWidget);
      expect(find.text('Atendimento'), findsOneWidget);
      await tester.tap(find.text('Atendimento'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Confirmar aprovacao
      expect(find.text('Confirmar aprovacao'), findsOneWidget);
      expect(find.text('Aprovar cliente'), findsOneWidget);
      await tester.tap(find.text('Aprovar cliente'));
      await tester.pumpAndSettle();

      // Verifica que a chamada foi enviada com os setores selecionados
      expect(aprovacaoEnviada, isTrue);
      expect(setoresEnviados, equals([7]));
      expect(find.text('Washington luis'), findsNothing);
    }, () => client);
  });
}
