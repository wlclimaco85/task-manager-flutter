import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:task_manager_flutter/mobile/widgets/ged_file_card_mobile.dart';

void main() {
  group('GedFileCardMobile', () {
    // Preparação comum para todos os testes
    late Map<String, dynamic> arqPadrao;

    setUp(() {
      arqPadrao = {
        'id': 1,
        'fileName': 'documento.pdf',
        'fileType': 'application/pdf',
        'diretorioNome': 'Contratos',
        'parceiroNome': 'Empresa XYZ',
        'uploadDate': '2026-07-15T10:30:00Z',
      };
    });

    testWidgets('Botão download deve chamar callback onDownload',
        (WidgetTester tester) async {
      var downloadChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {
                downloadChamado = true;
              },
              onDelete: () {},
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Procurar e clicar botão download
      final downloadButton =
          find.byIcon(Icons.download);
      expect(downloadButton, findsOneWidget,
          reason: 'Botão download deve estar visível');

      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      expect(downloadChamado, true,
          reason: 'onDownload callback deve ter sido chamado');
    });

    testWidgets('Dialog renomear deve abrir ao selecionar menu "Renomear"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {},
              onDelete: () {},
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Clicar menu "Mais ações"
      final maisAcoes = find.byIcon(Icons.more_vert);
      expect(maisAcoes, findsOneWidget,
          reason: 'Menu "mais ações" deve estar visível');

      await tester.tap(maisAcoes);
      await tester.pumpAndSettle();

      // Procurar "Renomear" no menu
      final renomearItem = find.text('Renomear');
      expect(renomearItem, findsOneWidget,
          reason: 'Item "Renomear" deve estar no menu');

      await tester.tap(renomearItem);
      await tester.pumpAndSettle();

      // Verificar TextField visível (modo edição)
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget,
          reason: 'TextField deve aparecer em modo edição');
    });

    testWidgets('Confirmar rename deve chamar onRename com novo nome',
        (WidgetTester tester) async {
      String? nomeRecebido;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {},
              onDelete: () {},
              onRename: (novoNome) async {
                nomeRecebido = novoNome;
                return true;
              },
            ),
          ),
        ),
      );

      // Abrir menu e selecionar "Renomear"
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      // Digitar novo nome
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'novo_documento.pdf');
      await tester.pumpAndSettle();

      // Clicar botão confirmar (check)
      final checkButton = find.byIcon(Icons.check);
      expect(checkButton, findsOneWidget,
          reason: 'Botão "Salvar" (check) deve aparecer em edição');

      await tester.tap(checkButton);
      await tester.pumpAndSettle();

      expect(nomeRecebido, 'novo_documento.pdf',
          reason: 'onRename deve ser chamado com novo nome');
    });

    testWidgets('Cancelar rename deve voltar ao estado normal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {},
              onDelete: () {},
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Abrir menu e selecionar "Renomear"
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      // Verificar TextField visível
      expect(find.byType(TextField), findsOneWidget);

      // Digitar algo
      await tester.enterText(find.byType(TextField), 'outro_nome.pdf');
      await tester.pumpAndSettle();

      // Clicar botão cancelar (X)
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget,
          reason: 'Botão cancelar deve estar visível');

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verificar que TextField desapareceu
      expect(find.byType(TextField), findsNothing,
          reason: 'TextField deve desaparecer após cancelar');

      // Verificar que texto original voltou
      final textoOriginal = find.text('documento.pdf');
      expect(textoOriginal, findsOneWidget,
          reason: 'Texto original deve ser restaurado');
    });

    testWidgets('Botão delete deve aparecer apenas com podeExcluir=true',
        (WidgetTester tester) async {
      // Criar com podeExcluir = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: false,
              onDownload: () {},
              onDelete: () {},
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Abrir menu
      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Verificar que "Excluir" NÃO aparece
      expect(find.text('Excluir'), findsNothing,
          reason: 'Botão "Excluir" não deve aparecer com podeExcluir=false');

      // Fechar menu
      await tester.tap(find.text('Renomear'));
      await tester.pumpAndSettle();

      // Rebuild com podeExcluir = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {},
              onDelete: () {},
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Abrir menu novamente
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Verificar que "Excluir" aparece agora
      expect(find.text('Excluir'), findsOneWidget,
          reason: 'Botão "Excluir" deve aparecer com podeExcluir=true');
    });

    testWidgets('Layout deve adaptar portrait/landscape sem overflow',
        (WidgetTester tester) async {
      // Portrait (400x800)
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GedFileCardMobile(
                arq: arqPadrao,
                podeExcluir: true,
                onDownload: () {},
                onDelete: () {},
                onRename: (_) async => true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget,
          reason: 'Card deve renderizar em portrait');

      // Landscape (800x400)
      tester.binding.window.physicalSizeTestValue = const Size(800, 400);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GedFileCardMobile(
                arq: arqPadrao,
                podeExcluir: true,
                onDownload: () {},
                onDelete: () {},
                onRename: (_) async => true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget,
          reason: 'Card deve renderizar em landscape sem erro');
    });

    testWidgets('Delete callback deve ser chamado ao selecionar "Excluir"',
        (WidgetTester tester) async {
      var deleteChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GedFileCardMobile(
              arq: arqPadrao,
              podeExcluir: true,
              onDownload: () {},
              onDelete: () {
                deleteChamado = true;
              },
              onRename: (_) async => true,
            ),
          ),
        ),
      );

      // Abrir menu e clicar "Excluir"
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(deleteChamado, true,
          reason: 'onDelete callback deve ter sido chamado');
    });
  });
}
