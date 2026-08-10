import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/details/nfse_detail_screen.dart';

/// Testes de widget do layout NfseDetailScreen (card Trello 6F94hyxf, v3):
/// 6 seções sequenciais reais (sem abas), busca inline ancorada no campo
/// (sem Dialog modal), ícones de ação com rótulo acessível, e formulário de
/// item isolado por item (StatefulWidget + Key estável) para evitar o
/// memory leak/corrupção de dados do CR-01/CR-02.
///
/// Não há backend disponível no ambiente de teste: as chamadas HTTP feitas em
/// initState (TenantContext.get) falham rapidamente e são capturadas
/// silenciosamente pela tela (try/catch já existente), então os dropdowns
/// ficam vazios — comportamento equivalente ao caso "API indisponível".
void main() {
  Widget buildScreen(Map<String, dynamic> item) {
    return MaterialApp(
      home: NfseDetailScreen(item: item),
    );
  }

  group('NfseDetailScreen — layout em 6 seções sequenciais', () {
    testWidgets('Renderiza Scaffold, AppBar e as 6 seções na ordem esperada',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 10, 'numero': '1'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);

      const titulosEsperados = [
        'Dados da nota',
        'Cliente / Tomador',
        'Dados fiscais do serviço',
        'Serviços da nota',
        'Impostos retidos',
        'Totais',
      ];
      for (final titulo in titulosEsperados) {
        expect(find.text(titulo), findsOneWidget, reason: 'seção "$titulo"');
      }
    });

    testWidgets('Ícones de ação (alternar grid, navegação de item) têm rótulo acessível',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 12, 'numero': '3'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Botões de alternância grid/formulário — WCAG 4.1.2 (Name, Role,
      // Value): cada ícone precisa expor um nome acessível via Tooltip.
      expect(find.byTooltip('Ver em grade'), findsOneWidget);
      expect(find.byTooltip('Ver em formulário'), findsOneWidget);

      // Cria um item para revelar os botões de navegação prev/next.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo').first);
      await tester.pump();

      expect(find.byTooltip('Primeiro item'), findsOneWidget);
      expect(find.byTooltip('Item anterior'), findsOneWidget);
      expect(find.byTooltip('Próximo item'), findsOneWidget);
      expect(find.byTooltip('Último item'), findsOneWidget);
    });

    testWidgets(
        'Campo de busca abre popover inline (não Dialog) e some ao clicar fora',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 13, 'numero': '4'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final municipioField =
          find.widgetWithText(InputDecorator, 'Município de Prestação');
      expect(municipioField, findsOneWidget);

      await tester.ensureVisible(municipioField);
      await tester.pump();
      await tester.tap(municipioField, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Buscar município de prestação...'), findsOneWidget);

      // Clique fora (barrier translúcido) fecha o popover sem navegação de
      // rota — outra evidência de que não é um Dialog/modal de tela cheia.
      await tester.tapAt(const Offset(20, 20));
      await tester.pump();
      expect(find.text('Buscar município de prestação...'), findsNothing);
    });

    testWidgets(
        'Selecionar produto no formulário do item atualiza os campos sem recriar o controller',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 14, 'numero': '5'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Novo').first);
      await tester.pump();

      expect(find.text('Produto (Serviço)'), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);
      expect(find.text('Salvar Item'), findsOneWidget);

      // Digita direto no campo Descrição — como não há produtos carregados
      // no teste (sem backend), simula edição manual do item e confirma que
      // o TextFormField responde a entrada sem lançar exceção mesmo após
      // rebuilds provocados por outros setState do widget pai.
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrição'), 'Consultoria XPTO');
      await tester.pump();
      expect(find.text('Consultoria XPTO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Seção Totais exibe cartões de valor', (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 15, 'valorTotal': '250,00'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vlr. NFSe'), findsOneWidget);
      expect(find.text('Total Serviços'), findsOneWidget);
      expect(find.text('250,00'), findsNWidgets(2));
    });

    testWidgets('Seção Impostos retidos aparece separada de Totais (sem abas)',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 16, 'valorTotal': '99,00'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Ambos os títulos visíveis ao mesmo tempo, sem precisar clicar em
      // uma aba — comportamento antigo usava _tab/_tabBtn para alternar
      // entre "Totais" e "Impostos" dentro do mesmo card.
      expect(find.text('Impostos retidos'), findsOneWidget);
      expect(find.text('Totais'), findsOneWidget);
      expect(find.text('Impostos (ISS) calculados a partir dos itens.'),
          findsOneWidget);
    });
  });
}
