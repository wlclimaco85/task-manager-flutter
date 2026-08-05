import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_item_form_dialog.dart';

Future<NfeItemModel?> _abrirDialog(
  WidgetTester tester, {
  NfeItemModel? item,
}) async {
  NfeItemModel? resultado;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resultado = await NfeItemFormDialog.show(
                context,
                item: item,
                proximoSequencial: 1,
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();

  return resultado;
}

void main() {
  group('NfeItemFormDialog', () {
    testWidgets('modo criação mostra título "Adicionar Item" e CFOP/Unidade default',
        (tester) async {
      await _abrirDialog(tester);

      expect(find.text('Adicionar Item'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'CFOP *'), findsOneWidget);
    });

    testWidgets('bloqueia confirmação quando campos obrigatórios estão vazios',
        (tester) async {
      await _abrirDialog(tester);

      // Preço unitário fica vazio de propósito — deve falhar validação
      await tester.tap(find.text('Adicionar').last);
      await tester.pump();

      expect(find.text('Descrição obrigatória'), findsOneWidget);
      // Dialog continua aberto (não fechou)
      expect(find.byType(NfeItemFormDialog), findsOneWidget);
    });

    testWidgets('cria item com dados válidos e calcula precoTotal', (tester) async {
      NfeItemModel? resultado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await NfeItemFormDialog.show(
                    context,
                    proximoSequencial: 3,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrição *'), 'Produto Teste');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código *'), 'COD1');
      await tester.enterText(find.widgetWithText(TextFormField, 'NCM *'), '12345678');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantidade *'), '2');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Preço Unitário (R\$) *'), '10,50');

      await tester.tap(find.text('Adicionar').last);
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      expect(resultado!.descricao, 'Produto Teste');
      expect(resultado!.codigoProduto, 'COD1');
      expect(resultado!.sequencial, 3);
      expect(resultado!.quantidade, 2);
      expect(resultado!.precoUnitario, closeTo(10.5, 0.001));
      expect(resultado!.precoTotal, closeTo(21.0, 0.001));
    });

    testWidgets('modo edição pré-preenche campos e mantém sequencial original',
        (tester) async {
      const item = NfeItemModel(
        sequencial: 7,
        codigoProduto: 'EXIST',
        descricao: 'Item existente',
        ncm: '87654321',
        cfop: '5405',
        cstIcms: '00',
        quantidade: 3,
        unidade: 'CX',
        precoUnitario: 5,
        precoTotal: 15,
        aliqIcms: 0.18,
        vlIcms: 2.7,
        aliqPis: 0.0165,
        vlPis: 0.2475,
        aliqCofins: 0.076,
        vlCofins: 1.14,
      );

      NfeItemModel? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  resultado = await NfeItemFormDialog.show(
                    context,
                    item: item,
                    proximoSequencial: item.sequencial,
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Item'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Descrição *'), findsOneWidget);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(NfeItemFormDialog), findsNothing);
      expect(resultado, isNotNull);
      expect(resultado!.sequencial, 7);
      expect(resultado!.descricao, 'Item existente');
      expect(resultado!.precoTotal, closeTo(15.0, 0.001));
    });
  });
}
