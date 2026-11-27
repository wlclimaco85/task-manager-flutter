import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/intercambio_contabil/intercambio_contabil_screen.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

http.Response _resposta({int novas = 2, int erros = 0, bool gravado = false}) =>
    http.Response.bytes(
        utf8.encode(jsonEncode({
          'total': 2,
          'novas': novas,
          'atualizadas': 0,
          'ignoradas': 0,
          'avisos': ['Aviso de teste'],
          'erros': [
            for (var i = 0; i < erros; i++) {'linha': i + 2, 'mensagem': 'Conta não encontrada $i'}
          ],
          'totalErros': erros,
          'gravado': gravado,
        })),
        200);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<void> abrir(WidgetTester t, Widget tela, [double largura = 1366]) async {
    t.view.physicalSize = Size(largura, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  // "ação" em Windows-1252, como o Excel em português costuma salvar.
  Future<ArquivoCsv?> arquivo() async =>
      ArquivoCsv('plano.csv', Uint8List.fromList([97, 231, 227, 111]));

  FilledButton botao(WidgetTester t, String rotulo) => t.widget<FilledButton>(
      find.ancestor(of: find.text(rotulo), matching: find.byWidgetPredicate((w) => w is FilledButton)));

  for (final largura in const [1366.0, 360.0]) {
    testWidgets('prévia válida e confirmação em ${largura.toInt()} px', (t) async {
      final urls = <String>[];
      String? corpo;
      await abrir(
          t,
          IntercambioContabilScreen(
            cabecalhoMobile: largura < 700,
            escolherArquivo: arquivo,
            enviar: (url, c) async {
              urls.add(url);
              corpo = c;
              return _resposta(gravado: url.contains('confirmar=true'));
            },
          ),
          largura);

      expect(find.byType(UserBannerAppBar), largura < 700 ? findsOneWidget : findsNothing);
      await t.tap(find.text('Escolher arquivo CSV'));
      await t.pumpAndSettle();
      expect(urls.single, contains('confirmar=false'));
      expect(jsonDecode(corpo!)['conteudo'], 'ação');

      await t.tap(find.text('Confirmar importação'));
      await t.pumpAndSettle();
      expect(urls.last, contains('confirmar=true'));
      expect(find.textContaining('Importação concluída: 2 novas'), findsOneWidget);
      expect(find.text('Confirmar importação'), findsNothing);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('com erro o botão de confirmar fica desabilitado', (t) async {
    await abrir(t,
        IntercambioContabilScreen(escolherArquivo: arquivo, enviar: (_, __) async => _resposta(erros: 2)));
    await t.tap(find.text('Escolher arquivo CSV'));
    await t.pumpAndSettle();

    expect(find.text('Linha 2: Conta não encontrada 0'), findsOneWidget);
    expect(botao(t, 'Confirmar importação').onPressed, isNull);
  });

  testWidgets('falha ao confirmar não afirma que nada foi gravado', (t) async {
    var chamadas = 0;
    await abrir(
        t,
        IntercambioContabilScreen(
            escolherArquivo: arquivo,
            enviar: (_, __) async => ++chamadas == 1 ? _resposta() : http.Response('', 500)));
    await t.tap(find.text('Escolher arquivo CSV'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirmar importação'));
    await t.pumpAndSettle();

    expect(find.textContaining('Verifique os dados antes de importar novamente'), findsOneWidget);
    expect(find.text('Confirmar importação'), findsNothing);
  });

  testWidgets('lançamentos só exportam com período', (t) async {
    await abrir(t, const IntercambioContabilScreen());
    await t.tap(find.text('Lançamentos'));
    await t.pumpAndSettle();

    expect(botao(t, 'Exportar CSV').onPressed, isNull);
    expect(find.text('Selecione o período para exportar.'), findsOneWidget);
  });

  testWidgets('exporta o plano e entrega o arquivo', (t) async {
    String? nome;
    await abrir(
        t,
        IntercambioContabilScreen(
            buscar: (_) async => http.Response('codigo', 200), salvar: (n, _) async => nome = n));
    await t.tap(find.text('Exportar CSV'));
    await t.pumpAndSettle();

    expect(nome, 'plano_de_contas.csv');
  });

  test('fica no menu Contábil', () {
    final contabil = MenuConfig.groups.firstWhere((g) => g.id == 'contabil').items.map((i) => i.id);
    expect(contabil, contains('intercambio_contabil'));
  });
}
