import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/nfe_xml_preview_widget.dart';

/// Cobre o bug de producao reportado pelo usuario (screenshot real da tela
/// "Importar XML NF-e"): a coluna "Produto" da tabela de itens aparecia
/// sempre "-" (chaves erradas: xProd/produto em vez de produtoDescricao) e
/// nao havia NENHUMA forma de conciliar o item importado com um produto ja
/// cadastrado (por sugestao de NCM) ou de marcar pra cadastrar um produto
/// novo. Este teste usa o formato REAL de resposta do backend
/// (NfeImportacaoItemDTO serializado por Jackson: produtoCodigo,
/// produtoDescricao, ncm, cfop, cst, quantidade, valorUnitario, total,
/// produtoSugeridoId, produtoSugeridoNome).
void main() {
  Map<String, dynamic> previewComItens(List<Map<String, dynamic>> itens) {
    return {
      'chave': '35260812345678000199550010000081301000081301',
      'numero': '8130',
      'serie': '1',
      'emitenteNome': 'FORNECEDOR TESTE LTDA',
      'dataEmissao': '2026-08-20',
      'valorTotal': '300.00',
      'itens': itens,
    };
  }

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      );

  testWidgets(
      'exibe o nome do produto na coluna Produto (bug: aparecia sempre "-")',
      (tester) async {
    final data = previewComItens([
      {
        'produtoCodigo': '36',
        'produtoDescricao': 'BERMUDA  JEANS PREMIUM',
        'ncm': '61034900',
        'cfop': '5102',
        'csosn': '102',
        'quantidade': '4',
        'valorUnitario': '75.0000000000',
        'total': '300.00',
      },
    ]);

    await tester.pumpWidget(wrap(NfeXmlPreviewWidget(
      data: data,
      onConfirm: (_) {},
      onCancel: () {},
    )));

    expect(find.text('BERMUDA  JEANS PREMIUM'), findsOneWidget);
    // CST vazio (item CSOSN, nao CST-regime) deve continuar mostrando "-"
    // legitimamente -- so o nome do produto era o bug.
  });

  testWidgets(
      'item com produtoSugeridoId vem pre-marcado pra usar o produto sugerido, '
      'e onConfirm recebe produtoId quando o usuario mantem a sugestao',
      (tester) async {
    List<Map<String, dynamic>>? enviado;

    final data = previewComItens([
      {
        'produtoCodigo': '36',
        'produtoDescricao': 'BERMUDA  JEANS PREMIUM',
        'ncm': '61034900',
        'cfop': '5102',
        'quantidade': '4',
        'valorUnitario': '75.00',
        'total': '300.00',
        'produtoSugeridoId': '501',
        'produtoSugeridoNome': 'BERMUDA JEANS PREMIUM (catálogo)',
      },
    ]);

    await tester.pumpWidget(wrap(NfeXmlPreviewWidget(
      data: data,
      onConfirm: (c) => enviado = c,
      onCancel: () {},
    )));

    expect(
        find.textContaining(
            'Usar produto já cadastrado:\nBERMUDA JEANS PREMIUM (catálogo)'),
        findsOneWidget);

    final checkbox = find.byType(CheckboxListTile);
    expect(checkbox, findsOneWidget);
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);

    await tester.tap(find.text('Confirmar Importação'));
    await tester.pump();

    expect(enviado, isNotNull);
    expect(enviado!.length, 1);
    expect(enviado!.first['produtoCodigo'], '36');
    expect(enviado!.first['produtoId'], 501);
    expect(enviado!.first['criarNovoProduto'], isFalse);
  });

  testWidgets(
      'desmarcando a sugestão o item deixa de enviar produtoId',
      (tester) async {
    List<Map<String, dynamic>>? enviado;

    final data = previewComItens([
      {
        'produtoCodigo': '36',
        'produtoDescricao': 'BERMUDA JEANS PREMIUM',
        'quantidade': '4',
        'valorUnitario': '75.00',
        'total': '300.00',
        'produtoSugeridoId': '501',
        'produtoSugeridoNome': 'BERMUDA JEANS PREMIUM (catálogo)',
      },
    ]);

    await tester.pumpWidget(wrap(NfeXmlPreviewWidget(
      data: data,
      onConfirm: (c) => enviado = c,
      onCancel: () {},
    )));

    // A tabela de itens rola horizontalmente; a célula de conciliação fica
    // fora da viewport inicial de teste (800x600) -- precisa trazer o
    // checkbox pra vista antes de tocar nele.
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('Confirmar Importação'));
    await tester.pump();

    expect(enviado!.first.containsKey('produtoId'), isFalse);
    expect(enviado!.first['criarNovoProduto'], isFalse);
  });

  testWidgets(
      'item sem sugestão (NCM não bateu com nenhum produto) oferece '
      'cadastrar produto novo, e onConfirm recebe criarNovoProduto=true '
      'quando marcado',
      (tester) async {
    List<Map<String, dynamic>>? enviado;

    final data = previewComItens([
      {
        'produtoCodigo': '99',
        'produtoDescricao': 'PRODUTO SEM CADASTRO PREVIO',
        'ncm': '12345678',
        'quantidade': '2',
        'valorUnitario': '10.00',
        'total': '20.00',
      },
    ]);

    await tester.pumpWidget(wrap(NfeXmlPreviewWidget(
      data: data,
      onConfirm: (c) => enviado = c,
      onCancel: () {},
    )));

    expect(find.text('Cadastrar como produto novo'), findsOneWidget);

    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('Confirmar Importação'));
    await tester.pump();

    expect(enviado!.first['produtoCodigo'], '99');
    expect(enviado!.first['criarNovoProduto'], isTrue);
    expect(enviado!.first.containsKey('produtoId'), isFalse);
  });
}
