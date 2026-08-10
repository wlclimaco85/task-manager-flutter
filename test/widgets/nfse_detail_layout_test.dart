import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/details/nfse_detail_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets(
      'NFSe detail usa 6 secoes sequenciais reais (sem abas Totais/Impostos)',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    // As 6 secoes pedidas pelo card (Dados da nota / Cliente-Tomador /
    // Dados fiscais do servico / Servicos da nota / Impostos retidos /
    // Totais) devem estar TODAS visiveis simultaneamente na arvore, sem
    // precisar clicar em aba para revelar Impostos ou Totais — provando que
    // o padrao de abas (_tab/_tabBtn) foi removido.
    expect(find.text('Dados da nota'), findsOneWidget);
    expect(find.text('Cliente / Tomador'), findsOneWidget);
    expect(find.text('Dados fiscais do serviço'), findsOneWidget);
    expect(find.text('Serviços da nota'), findsOneWidget);
    expect(find.text('Impostos retidos'), findsOneWidget);
    expect(find.text('Totais'), findsOneWidget);
  });

  testWidgets(
      'NFSe detail: secoes aparecem em ordem vertical unica (sem paineis lado a lado)',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    final dadosNota = tester.getTopLeft(find.text('Dados da nota'));
    final cliente = tester.getTopLeft(find.text('Cliente / Tomador'));
    final fiscais = tester.getTopLeft(find.text('Dados fiscais do serviço'));
    final servicos = tester.getTopLeft(find.text('Serviços da nota'));
    final impostos = tester.getTopLeft(find.text('Impostos retidos'));
    final totais = tester.getTopLeft(find.text('Totais'));

    // Mesma coluna X (mesma largura de card, sem cabecalho estreito a
    // esquerda + grid a direita) e Y estritamente crescente na ordem
    // sequencial esperada.
    expect(cliente.dx, dadosNota.dx);
    expect(fiscais.dx, dadosNota.dx);
    expect(servicos.dx, dadosNota.dx);
    expect(impostos.dx, dadosNota.dx);
    expect(totais.dx, dadosNota.dx);

    expect(cliente.dy, greaterThan(dadosNota.dy));
    expect(fiscais.dy, greaterThan(cliente.dy));
    expect(servicos.dy, greaterThan(fiscais.dy));
    expect(impostos.dy, greaterThan(servicos.dy));
    expect(totais.dy, greaterThan(impostos.dy));
  });

  test('NFSe resolve codigo municipal pelo IBGE retornado em cidade', () {
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigoServicoMunicipal': '101'},
      ),
      '101',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigo_servico_municipal': '202'},
      ),
      '202',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigoServico': '303'},
      ),
      '303',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'codigo_servico': '404'},
      ),
      '404',
    );
    expect(
      resolveCodigoServicoMunicipalNfse(
        {'id': 9999, 'nome': 'Uberaba', 'ibge': 3170107},
      ),
      '3170107',
    );
  });

  testWidgets('NFSe detail alterna cabecalho para formulario de servicos',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    final novoButton = find.widgetWithText(ElevatedButton, 'Novo').first;
    await tester.scrollUntilVisible(novoButton, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(novoButton);
    await tester.pump();

    expect(find.textContaining('Produto'), findsWidgets);
    expect(find.text('Salvar Item'), findsOneWidget);
  });

  testWidgets(
      'NFSe detail abre busca inline ancorada no campo, SEM Dialog modal',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    final serieField = find.widgetWithText(InputDecorator, 'Série');
    expect(serieField, findsOneWidget);
    await tester.tap(serieField);
    await tester.pump(const Duration(milliseconds: 300));

    // Requisito real do card: busca sem modal de tela cheia. A asercao
    // correta é a AUSÊNCIA de Dialog — o teste anterior (reprovado em QA)
    // tinha titulo enganoso e na verdade afirmava find.byType(Dialog),
    // findsOneWidget, confirmando que a busca continuava modal. Aqui
    // verificamos o oposto: nenhum Dialog é aberto, e o popover de busca
    // (com campo de texto) aparece ancorado, coexistindo com o resto do
    // formulário na tela.
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Dados da nota'), findsOneWidget);
    expect(find.text('Cliente / Tomador'), findsOneWidget);
    expect(find.textContaining('Buscar'), findsOneWidget);
  });

  testWidgets(
      'NFSe detail preenche codigo municipal a partir do IBGE da cidade',
      (tester) async {
    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {
      'municipioPrestacao': 'Uberaba',
      'cidade': {'id': 1, 'nome': 'Uberaba', 'ibge': 3170107},
    })));
    await tester.pump();

    final codigoField =
        find.widgetWithText(TextFormField, 'Código de Serviço Municipal');

    expect(codigoField, findsOneWidget);
    expect((tester.widget(codigoField) as TextFormField).controller?.text,
        '3170107');
  });

  testWidgets('NFSe detail nao estoura em largura estreita', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
    await tester.pump();

    expect(tester.takeException(), isNull);

    final novoButton = find.widgetWithText(ElevatedButton, 'Novo').first;
    await tester.drag(
        find.byType(SingleChildScrollView).first, const Offset(0, -300));
    await tester.pump();
    await tester.tap(novoButton);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Serviços da nota'), findsOneWidget);
  });

  group('Regressao CR-01/CR-02 — controllers isolados por item', () {
    /// Lê o texto atual exibido no campo "Descrição" do formulário do item
    /// (card "Serviços da nota"). Usa o `controller.text` do
    /// [TextFormField] em vez de `find.text(...)` na tela inteira, porque o
    /// card "Impostos retidos" também renderiza a descrição de cada item já
    /// salvo na lista como texto simples — coexistência legítima que não
    /// deve ser confundida com vazamento entre formulários.
    String descricaoDoFormulario(WidgetTester tester) {
      final field =
          tester.widget(find.widgetWithText(TextFormField, 'Descrição'))
              as TextFormField;
      return field.controller?.text ?? '';
    }

    testWidgets(
        'editar item 1 e depois item 2 nao mistura nem perde valores digitados',
        (tester) async {
      await tester.pumpWidget(_wrap(const NfseDetailScreen(item: {})));
      await tester.pump();

      final novoButton = find.widgetWithText(ElevatedButton, 'Novo').first;
      await tester.scrollUntilVisible(novoButton, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pump();

      // Cria item 1 e digita sua descricao.
      await tester.tap(novoButton);
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Descrição'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrição'), 'Servico Item 1');
      await tester.pump();
      expect(descricaoDoFormulario(tester), 'Servico Item 1');

      // Cria item 2 (navega automaticamente para ele) — o formulario do
      // ITEM ATUAL deve vir vazio, NAO deve reaproveitar o texto do item 1
      // (prova que cada item tem seu proprio TextEditingController, nao um
      // Map global por nome de campo compartilhado entre itens — CR-02).
      await tester.tap(novoButton);
      await tester.pump();
      expect(descricaoDoFormulario(tester), isEmpty);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrição'), 'Servico Item 2');
      await tester.pump();
      expect(descricaoDoFormulario(tester), 'Servico Item 2');

      // Volta para o item 1 (botao "primeiro item") — o valor digitado
      // antes precisa continuar intacto (persistido no Map do item, e
      // reidratado em um NOVO TextEditingController criado no initState do
      // widget do item 1, sem vazamento do controller do item 2 — CR-01).
      final primeiroItemBtn = find.byTooltip('Primeiro item');
      expect(primeiroItemBtn, findsOneWidget);
      await tester.tap(primeiroItemBtn);
      await tester.pump();

      expect(descricaoDoFormulario(tester), 'Servico Item 1');

      // Nenhuma excecao de "controller used after being disposed" ou
      // similar ao longo de toda a navegacao entre itens.
      expect(tester.takeException(), isNull);

      // Avanca de novo para o item 2 — o valor digitado la tambem precisa
      // ter sido preservado (nao apenas o item 1).
      final proximoItemBtn = find.byTooltip('Próximo item');
      expect(proximoItemBtn, findsOneWidget);
      await tester.tap(proximoItemBtn);
      await tester.pump();

      expect(descricaoDoFormulario(tester), 'Servico Item 2');
      expect(tester.takeException(), isNull);
    });
  });
}
