import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/nfse_xml_preview_widget.dart';

void main() {
  Map<String, dynamic> dadosBase({bool duplicata = false, int? produtoSugeridoId}) {
    return {
      'numero': '2026000000073',
      'codigoVerificacao': 'QRJR-2DZ1',
      'tomadorRazaoSocial': 'LANNA COMERCIO',
      'tomadorCnpj': '38504938000707',
      'dataEmissao': '2026-08-04T11:26:26',
      'discriminacao': 'PRESTACAO DE SERVICO CONTABIL',
      'valorServicos': '1621',
      'aliquotaIss': '3',
      'valorIss': '48.63',
      'duplicata': duplicata,
      if (produtoSugeridoId != null) 'produtoSugeridoId': produtoSugeridoId,
      if (produtoSugeridoId != null) 'produtoSugeridoNome': 'Servico Contabil',
    };
  }

  testWidgets('exibe os dados da nota e o badge de nota nova', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NfseXmlPreviewWidget(
          data: dadosBase(),
          onConfirm: ({produtoId, criarNovoProduto = false}) {},
          onCancel: () {},
        ),
      ),
    ));

    expect(find.text('NFS-e nova'), findsOneWidget);
    expect(find.textContaining('LANNA COMERCIO'), findsOneWidget);
    expect(find.textContaining('PRESTACAO DE SERVICO CONTABIL'), findsOneWidget);
  });

  testWidgets('exibe badge de nota ja importada quando duplicata', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NfseXmlPreviewWidget(
          data: dadosBase(duplicata: true),
          onConfirm: ({produtoId, criarNovoProduto = false}) {},
          onCancel: () {},
        ),
      ),
    ));

    expect(find.text('NFS-e ja importada'), findsOneWidget);
  });

  testWidgets('confirma com criarNovoProduto=true quando nao ha sugestao', (tester) async {
    int? produtoIdRecebido;
    bool criarNovoRecebido = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NfseXmlPreviewWidget(
          data: dadosBase(),
          onConfirm: ({produtoId, criarNovoProduto = false}) {
            produtoIdRecebido = produtoId;
            criarNovoRecebido = criarNovoProduto;
          },
          onCancel: () {},
        ),
      ),
    ));

    await tester.tap(find.text('Confirmar Importacao'));
    await tester.pump();

    expect(produtoIdRecebido, isNull);
    expect(criarNovoRecebido, isTrue);
  });

  testWidgets('confirma com o produtoId sugerido quando usuario aceita a sugestao', (tester) async {
    int? produtoIdRecebido;
    bool criarNovoRecebido = true;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NfseXmlPreviewWidget(
          data: dadosBase(produtoSugeridoId: 42),
          onConfirm: ({produtoId, criarNovoProduto = false}) {
            produtoIdRecebido = produtoId;
            criarNovoRecebido = criarNovoProduto;
          },
          onCancel: () {},
        ),
      ),
    ));

    expect(find.textContaining('Servico Contabil'), findsOneWidget);

    await tester.tap(find.text('Confirmar Importacao'));
    await tester.pump();

    expect(produtoIdRecebido, 42);
    expect(criarNovoRecebido, isFalse);
  });
}
