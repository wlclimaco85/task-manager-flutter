import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/controle_obrigacoes/controle_obrigacoes_screen.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);

Map<String, dynamic> _linha(int parceiro, String empresa, String situacao) => {
      'parceiroId': parceiro,
      'obrigacaoId': 10,
      'empresa': empresa,
      'regimeId': 3,
      'regime': 'Simples Nacional',
      'obrigacao': 'DAS - Documento de Arrecadação do Simples Nacional',
      'vencimento': '2026-01-20',
      'situacao': situacao,
    };

void main() {
  setUpAll(() => SharedPreferences.setMockInitialValues({}));

  Future<http.Response> lista(String url) async => _json({
        'linhas': [
          _linha(1, 'Alfa Comércio de Materiais de Construção Ltda', 'ATRASADA'),
          _linha(2, 'Beta', 'PENDENTE'),
          _linha(3, 'Gama', 'ENTREGUE'),
        ]
      });

  Future<void> abrir(WidgetTester t, Widget tela, [double largura = 1366]) async {
    t.view.physicalSize = Size(largura, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: tela));
    await t.pumpAndSettle();
  }

  for (final largura in const [1366.0, 800.0, 360.0]) {
    testWidgets('seleciona as abertas e registra em lote em ${largura.toInt()} px', (t) async {
      final corpos = <Map<String, dynamic>>[];
      await abrir(
          t,
          ControleObrigacoesScreen(
            cabecalhoMobile: largura < 700,
            buscar: lista,
            enviar: (url, corpo) async {
              expect(url, contains('/api/controle-obrigacoes/registro'));
              corpos.add(jsonDecode(corpo) as Map<String, dynamic>);
              return _json({'registrados': 2});
            },
          ),
          largura);

      expect(find.byType(UserBannerAppBar), largura < 700 ? findsOneWidget : findsNothing);
      expect(find.textContaining('não transmite nada ao governo'), findsOneWidget);
      expect(find.text('1 de 3 entregues'), findsOneWidget);

      await t.tap(find.text('Selecionar pendentes e atrasadas (2)'));
      await t.pumpAndSettle();
      await t.tap(find.text('Marcar como entregues'));
      await t.pumpAndSettle();
      expect(find.text('Protocolo (opcional)'), findsNothing); // lote não tem protocolo
      await t.tap(find.text('Registrar 2 entregas'));
      await t.pumpAndSettle();

      expect(corpos.single['acao'], 'ENTREGAR');
      expect((corpos.single['itens'] as List).map((i) => i['parceiroId']), [1, 2]);
      expect(corpos.single['dataEntrega'], isNotNull);
      expect(find.text('2 entregas registradas.'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('dispensa exige motivo, e erro do servidor mantém o diálogo', (t) async {
    var envios = 0;
    await abrir(
        t,
        ControleObrigacoesScreen(
          buscar: lista,
          enviar: (_, __) async {
            envios++;
            return _json({'message': 'Atualize a lista.'}, 400);
          },
        ));

    await t.tap(find.byTooltip('Mais ações').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Dispensar'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Dispensar'));
    await t.pumpAndSettle();
    expect(find.text('Informe o motivo da dispensa.'), findsOneWidget);
    expect(envios, 0);

    await t.enterText(find.byType(TextField), 'Sem movimento');
    await t.tap(find.widgetWithText(FilledButton, 'Dispensar'));
    await t.pumpAndSettle();
    expect(find.text('Atualize a lista.'), findsOneWidget);
    expect(find.text('Dispensar obrigação'), findsOneWidget);
  });

  testWidgets('contador filtra por situação e linha entregue não é selecionável', (t) async {
    await abrir(t, const SizedBox());
    await abrir(t, ControleObrigacoesScreen(buscar: lista));

    await t.tap(find.text('Entregues: 1'));
    await t.pumpAndSettle();
    expect(find.text('Gama'), findsOneWidget);
    expect(find.text('Beta'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('403 mostra falta de acesso sem tentar de novo', (t) async {
    await abrir(t, ControleObrigacoesScreen(buscar: (_) async => _json({}, 403)), 360);
    expect(find.textContaining('Você não tem acesso ao Controle de Obrigações'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
  });

  test('tela está no menu Contábil', () {
    final contabil = MenuConfig.groups.firstWhere((g) => g.id == 'contabil');
    expect(contabil.items.map((i) => i.id), contains('controle_obrigacoes'));
  });
}
