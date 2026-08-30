import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/details/nfse_detail_screen.dart';

/// Testes de widget do novo layout de NfseDetailScreen — layout reorganizado
/// (2026-08) em seções sequenciais (Dados da Nota, Itens, Impostos, Totais),
/// substituindo o antigo layout de coluna estreita + grid lateral
/// redimensionável (card Trello 6F94hyxf).
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

  group('NfseDetailScreen — layout reorganizado em seções', () {
    testWidgets('Renderiza Scaffold, AppBar e as 4 seções principais',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 10, 'numero': '1'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // A tela em si tem 1 Scaffold; o grid de itens (DynamicGridWindowsScreen)
      // pode conter outro Scaffold interno — verificamos "pelo menos um".
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);

      // As 4 seções sequenciais devem existir, na ordem esperada.
      expect(find.byKey(const Key('secao_dados_nota')), findsOneWidget);
      expect(find.byKey(const Key('secao_itens')), findsOneWidget);
      expect(find.byKey(const Key('secao_impostos')), findsOneWidget);
      expect(find.byKey(const Key('secao_totais')), findsOneWidget);

      expect(find.text('Dados da Nota'), findsOneWidget);
      expect(find.text('Itens (Serviços)'), findsOneWidget);
      expect(find.text('Impostos'), findsOneWidget);
      expect(find.text('Totais'), findsOneWidget);
    });

    testWidgets('Seções aparecem em Column vertical única (sem split lateral)',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 11, 'numero': '2'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final dadosNota =
          tester.getTopLeft(find.byKey(const Key('secao_dados_nota')));
      final itens = tester.getTopLeft(find.byKey(const Key('secao_itens')));
      final impostos =
          tester.getTopLeft(find.byKey(const Key('secao_impostos')));
      final totais = tester.getTopLeft(find.byKey(const Key('secao_totais')));

      // Navegação cabeçalho → itens → impostos → totais: cada seção fica
      // abaixo da anterior (mesma coluna X, Y crescente) — evidência de que
      // o layout não usa mais Row lateral (cabeçalho estreito + grid ao lado).
      expect(dadosNota.dx, itens.dx);
      expect(itens.dx, impostos.dx);
      expect(impostos.dx, totais.dx);
      expect(itens.dy, greaterThan(dadosNota.dy));
      expect(impostos.dy, greaterThan(itens.dy));
      expect(totais.dy, greaterThan(impostos.dy));
    });

    testWidgets(
        'Campos do cabeçalho usam SearchableDropdownField e abrem busca',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 12, 'numero': '3'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final municipioField = find.text('Município de Prestação');
      expect(municipioField, findsOneWidget);

      await tester.ensureVisible(municipioField);
      await tester.pump();
      await tester.tap(municipioField, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Abre o diálogo de busca (mesmo componente reusado — fora de escopo
      // desta correção alterar o SearchableDropdownField compartilhado).
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Buscar município de prestação...'), findsOneWidget);
    });

    testWidgets('Alterna entre visão em grid e formulário de item',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 13, 'numero': '4'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Botão "Novo" cria um item vazio e alterna para o formulário.
      expect(find.text('Novo'), findsOneWidget);
      await tester.tap(find.text('Novo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Produto (Serviço)'), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);
      expect(find.text('Salvar Item'), findsOneWidget);
    });

    testWidgets('Seção Totais exibe cartões de valor',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 14, 'valorTotal': '250,00'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vlr. NFSe'), findsOneWidget);
      expect(find.text('Total Serviços'), findsOneWidget);
      expect(find.text('250,00'), findsNWidgets(2));
    });

    testWidgets('Cabeçalho das seções não estoura em viewport estreita',
        (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(520, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildScreen({'id': 15, 'numero': '5'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('secao_itens')), findsOneWidget);
      expect(find.text('Novo'), findsOneWidget);
    });
  });

  // Card 4phuZyDS: mesma wiring de Emitir/Cancelar aplicada à versão web
  // (ver test/web/screens/details/nfse_detail_screen_test.dart), replicada
  // aqui para a versão windows.
  group('Card 4phuZyDS — botões Emitir/Cancelar (windows)', () {
    testWidgets('NFSe nova (sem id) não mostra botões Emitir/Cancelar',
        (tester) async {
      await tester
          .pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
      await tester.pump();

      expect(find.widgetWithText(OutlinedButton, 'Emitir'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsNothing);
    });

    testWidgets(
        'NFSe existente mostra botões Emitir/Cancelar e bloqueia envio sem tomador/itens',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(item: const {'id': 601, 'status': 'PENDENTE'})));
      await tester.pump();

      expect(find.widgetWithText(OutlinedButton, 'Emitir'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Emitir'));
      await tester.pump();

      expect(find.textContaining('Preencha antes de emitir'), findsOneWidget);
    });

    testWidgets('Status em inglês (ISSUED) é exibido traduzido no chip',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(1400, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
          home: NfseDetailScreen(item: const {'id': 602, 'status': 'ISSUED'})));
      await tester.pump();

      expect(find.text('Autorizada pela prefeitura'), findsOneWidget);
      expect(find.text('ISSUED'), findsNothing);
    });
  });
}
