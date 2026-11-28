import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/certidoes/certidoes_screen.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<http.Response> lista(String url) async {
    if (url.contains('/pdf')) return http.Response('%PDF', 200);
    return _json({
      'tipos': [
        {'codigo': 'CND_FEDERAL', 'nome': 'Federal'},
        {'codigo': 'CND_FGTS', 'nome': 'FGTS'},
      ],
      'clientes': [
        {'parceiroId': 5, 'nome': 'Alfa Comércio de Materiais de Construção e Acabamentos Ltda'},
        {'parceiroId': 6, 'nome': 'Beta'},
      ],
      'certidoes': [
        {
          'id': 1,
          'parceiroId': 6,
          'tipo': 'CND_FGTS',
          'resultado': 'POSITIVA',
          'numero': '2026/000123456789',
          'dataVencimento': '2099-01-20',
          'temArquivo': true,
          'situacao': 'IRREGULAR',
        }
      ],
    });
  }

  Future<void> abrir(WidgetTester t, Widget tela, [double largura = 1366]) async {
    t.view.physicalSize = Size(largura, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  for (final largura in const [1366.0, 800.0, 360.0]) {
    testWidgets('painel, filtro por contador e download em ${largura.toInt()} px', (t) async {
      String? nome;
      await abrir(
          t,
          CertidoesScreen(
              cabecalhoMobile: largura < 700, buscar: lista, salvar: (n, _) async => nome = n),
          largura);

      expect(find.byType(UserBannerAppBar), largura < 700 ? findsOneWidget : findsNothing);
      expect(find.textContaining('nada é consultado no órgão'), findsOneWidget);
      expect(find.text('Sem certidão: 5'), findsOneWidget);

      await t.tap(find.text('Irregulares: 1'));
      await t.pumpAndSettle();
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Minha empresa'), findsNothing);
      expect(find.text('Positiva'), findsOneWidget);

      await t.tap(find.byTooltip('Baixar PDF, FGTS, Beta'));
      await t.pumpAndSettle();
      expect(nome, 'certidao_fgts_1.pdf');
      expect(t.takeException(), isNull);
    });

    testWidgets('envio exige campos e omite titular da própria empresa em ${largura.toInt()} px',
        (t) async {
      Map<String, String>? campos;
      await abrir(
          t,
          CertidoesScreen(
            buscar: lista,
            escolherArquivo: () async => ArquivoPdf('c.pdf', Uint8List.fromList([37, 80, 68, 70, 45])),
            enviar: (url, c, a) async {
              expect(url, contains('/api/certidoes'));
              campos = c;
              return _json({'id': 2});
            },
          ),
          largura);

      await t.tap(find.text('Minha empresa'));
      await t.pumpAndSettle();
      await t.tap(find.text('Enviar').first);
      await t.pumpAndSettle();
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.text('Preencha os campos com * e selecione o PDF.'), findsOneWidget);
      expect(campos, isNull);

      await t.tap(find.text('Resultado*'));
      await t.pumpAndSettle();
      await t.tap(find.text('Negativa').last);
      await t.pumpAndSettle();
      for (final rotulo in ['Data de emissão*', 'Data de vencimento*']) {
        await t.ensureVisible(find.text(rotulo));
        await t.tap(find.text(rotulo));
        await t.pumpAndSettle();
        await t.tap(find.text('OK'));
        await t.pumpAndSettle();
      }
      await t.ensureVisible(find.text('Selecionar PDF* (até 10 MB)'));
      await t.tap(find.text('Selecionar PDF* (até 10 MB)'));
      await t.pumpAndSettle();
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();

      expect(campos!.containsKey('titularId'), isFalse);
      expect(campos!['tipo'], 'CND_FEDERAL');
      expect(campos!['resultado'], 'NEGATIVA');
      expect(find.text('Certidão registrada.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('403 mostra falta de acesso sem enviar nem tentar de novo', (t) async {
    await abrir(t, CertidoesScreen(buscar: (_) async => _json({}, 403)), 360);
    expect(find.textContaining('Você não tem acesso a Certidões'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    expect(find.text('Enviar certidão'), findsNothing);
  });

  test('tela está no menu Contábil', () {
    final contabil = MenuConfig.groups.firstWhere((g) => g.id == 'contabil');
    expect(contabil.items.map((i) => i.id), contains('certidoes'));
  });
}
