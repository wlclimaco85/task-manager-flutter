// test/widgets/login_empresa_acesso_aprovacao_screen_test.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/login_empresa_acesso_caller.dart';
import 'package:task_manager_flutter/widgets/login_empresa_acesso_aprovacao_screen.dart';

void main() {
  final originalClient = LoginEmpresaAcessoCaller.client;

  tearDown(() {
    LoginEmpresaAcessoCaller.client = originalClient;
  });

  /// A DataTable com 5 colunas nao cabe no tamanho padrao de teste
  /// (800x600) e gera overflow/hit-test fora da tela ao tocar nos icones de
  /// acao — aumenta a superficie de teste para caber a tabela inteira.
  void ampliarSuperficieDeTeste(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildApp() => const MaterialApp(
        home: LoginEmpresaAcessoAprovacaoScreen(),
      );

  testWidgets('lista vazia mostra mensagem "Nenhuma solicitação pendente"',
      (tester) async {
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      return http.Response(jsonEncode({'data': []}), 200);
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma solicitação pendente'), findsOneWidget);
  });

  testWidgets('erro de rede mostra estado de erro com botão Tentar novamente',
      (tester) async {
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      throw Exception('falha de rede simulada');
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as solicitações'),
        findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets(
      'item presente com aprovar/rejeitar: aprovar chama o caller e remove o item da lista',
      (tester) async {
    ampliarSuperficieDeTeste(tester);
    var chamouAprovar = false;
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 42,
                'loginNome': 'Fulano de Tal',
                'loginEmail': 'fulano@teste.com',
                'empresaNome': 'Empresa Alvo',
                'dataCriacao': '2026-08-29T10:00:00',
              }
            ]
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/aprovar')) {
        chamouAprovar = true;
        return http.Response('', 200);
      }
      return http.Response('', 404);
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Fulano de Tal'), findsOneWidget);

    await tester.tap(find.byTooltip('Aprovar'));
    await tester.pumpAndSettle();

    // Dialogo de confirmacao
    expect(find.text('Aprovar acesso'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Aprovar'));
    await tester.pumpAndSettle();

    expect(chamouAprovar, isTrue);
    expect(find.text('Fulano de Tal'), findsNothing);
    expect(find.text('Nenhuma solicitação pendente'), findsOneWidget);
  });

  testWidgets('rejeitar remove o item da lista em sucesso', (tester) async {
    ampliarSuperficieDeTeste(tester);
    var chamouRejeitar = false;
    LoginEmpresaAcessoCaller.client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 7,
                'loginNome': 'Ciclana',
                'loginEmail': 'ciclana@teste.com',
                'empresaNome': 'Empresa Y',
                'dataCriacao': '2026-08-29T10:00:00',
              }
            ]
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/rejeitar')) {
        chamouRejeitar = true;
        return http.Response('', 200);
      }
      return http.Response('', 404);
    });

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rejeitar'));
    await tester.pumpAndSettle();

    expect(find.text('Rejeitar solicitação'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Rejeitar'));
    await tester.pumpAndSettle();

    expect(chamouRejeitar, isTrue);
    expect(find.text('Ciclana'), findsNothing);
  });
}
