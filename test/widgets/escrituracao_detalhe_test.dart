import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/features/escrituracao_fiscal/screens/escrituracao_detalhe_screen.dart';
import 'package:task_manager_flutter/models/escrituracao_fiscal_model.dart';
import 'package:task_manager_flutter/services/escrituracao_fiscal_service.dart';

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

EscrituracaoFiscal _esc(String status) =>
    EscrituracaoFiscal(id: 1, empresaId: 7, periodo: '2026-10', tipo: 'ENTRADA', status: status);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  final cliente = MockClient((req) async => req.url.path.endsWith('/exportar')
      ? http.Response('Periodo;Tipo', 200)
      : _json([]));

  for (final caso in const [('ABERTO', 'Conferir'), ('CONFERIDO', 'Fechar'), ('FECHADO', null)]) {
    testWidgets('situação ${caso.$1} mostra a ação certa', (t) async {
      await http.runWithClient(() async {
        await t.pumpWidget(MaterialApp(home: EscrituracaoDetalheScreen(escrituracao: _esc(caso.$1))));
        await t.pumpAndSettle();
      }, () => cliente);
      for (final acao in const ['Conferir', 'Fechar']) {
        expect(find.text(acao), acao == caso.$2 ? findsOneWidget : findsNothing);
      }
      expect(find.byTooltip('Exportar CSV'), findsOneWidget);
    });
  }

  for (final mobile in const [false, true]) {
    testWidgets('exporta o CSV (cabeçalho mobile: $mobile)', (t) async {
      String? nome;
      List<int>? bytes;
      t.view.physicalSize = Size(mobile ? 360 : 1366, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await http.runWithClient(() async {
        await t.pumpWidget(MaterialApp(
            home: EscrituracaoDetalheScreen(
                escrituracao: _esc('FECHADO'),
                cabecalhoMobile: mobile,
                salvar: (n, b) async {
                  nome = n;
                  bytes = b;
                })));
        await t.pumpAndSettle();
        await t.tap(find.byTooltip('Exportar CSV'));
        await t.pumpAndSettle();
      }, () => cliente);
      expect(nome, 'escrituracao-2026-10-entrada.csv');
      expect(utf8.decode(bytes!), 'Periodo;Tipo');
    });
  }

  test('recusa do servidor não vira escrituração vazia', () async {
    await expectLater(
      http.runWithClient(() => EscrituracaoFiscalService().fechar(1),
          () => MockClient((_) async => _json({'message': 'Confira a escrituração antes de fechar.'}, 400))),
      throwsA(isA<EscrituracaoFiscalException>()
          .having((e) => e.message, 'message', 'Confira a escrituração antes de fechar.')),
    );
  });

  test('erro que não é JSON vira mensagem legível', () async {
    await expectLater(
      http.runWithClient(() => EscrituracaoFiscalService().fechar(1),
          () => MockClient((_) async => http.Response('<html>502</html>', 502))),
      throwsA(isA<EscrituracaoFiscalException>()
          .having((e) => e.message, 'message', 'Erro ao processar escrituração (502).')),
    );
  });
}
