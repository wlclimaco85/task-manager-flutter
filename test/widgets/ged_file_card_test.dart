import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/web/widgets/ged_file_card.dart';

void main() {
  Map<String, dynamic> arquivoBase() => {
        'id': 1,
        'fileName': 'contrato.pdf',
        'fileType': 'application/pdf',
        'diretorioNome': 'Contratos',
        'parceiroNome': 'Empresa XPTO',
        'uploadDate': '2026-06-01T10:00:00',
      };

  Widget buildCard({
    Map<String, dynamic>? arq,
    bool podeExcluir = true,
    VoidCallback? onDownload,
    VoidCallback? onDelete,
    Future<bool> Function(String novoNome)? onRename,
    VoidCallback? onClassify,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GedFileCard(
          arq: arq ?? arquivoBase(),
          podeExcluir: podeExcluir,
          onDownload: onDownload ?? () {},
          onDelete: onDelete ?? () {},
          onRename: onRename ?? (_) async => true,
          onClassify: onClassify ?? () {},
        ),
      ),
    );
  }

  testWidgets('renderiza nome do arquivo e chip de tipo', (tester) async {
    await tester.pumpWidget(buildCard());

    expect(find.text('contrato.pdf'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
  });

  testWidgets('exibe PopupMenuButton com itens Renomear e Classificar com IA',
      (tester) async {
    await tester.pumpWidget(buildCard());

    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Renomear'), findsOneWidget);
    expect(find.text('Classificar com IA'), findsOneWidget);
  });

  testWidgets(
      'toca Renomear, edita o nome e confirma chamando onRename com o novo nome',
      (tester) async {
    String? nomeRecebido;

    await tester.pumpWidget(buildCard(onRename: (novoNome) async {
      nomeRecebido = novoNome;
      return true;
    }));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'NovoNome');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(nomeRecebido, 'NovoNome');
  });

  testWidgets(
      'toca Renomear, confirma sem alterar o nome e não chama onRename',
      (tester) async {
    var chamado = false;

    await tester.pumpWidget(buildCard(onRename: (_) async {
      chamado = true;
      return true;
    }));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(chamado, isFalse);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('toca Renomear, apaga o nome e confirma não chama onRename',
      (tester) async {
    var chamado = false;

    await tester.pumpWidget(buildCard(onRename: (_) async {
      chamado = true;
      return true;
    }));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(chamado, isFalse);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('toca Classificar com IA chama onClassify', (tester) async {
    var chamado = false;

    await tester.pumpWidget(buildCard(onClassify: () => chamado = true));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Classificar com IA'));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
  });

  testWidgets('quando podeExcluir é false, não exibe ícone de excluir',
      (tester) async {
    await tester.pumpWidget(buildCard(podeExcluir: false));

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets(
      'quando podeExcluir é true, exibe ícone de excluir e chama onDelete ao tocar',
      (tester) async {
    var chamado = false;

    await tester.pumpWidget(
      buildCard(podeExcluir: true, onDelete: () => chamado = true),
    );

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
  });

  testWidgets('ícone de download está sempre presente e chama onDownload',
      (tester) async {
    var chamado = false;

    await tester.pumpWidget(buildCard(onDownload: () => chamado = true));

    expect(find.byIcon(Icons.download), findsOneWidget);

    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();

    expect(chamado, isTrue);
  });
}
