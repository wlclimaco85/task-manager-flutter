import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';

void main() {
  group('NfeItemsTable._formatCurrency', () {
    NfeItemModel itemComTotal(double precoTotal) {
      return NfeItemModel(
        sequencial: 1,
        codigoProduto: 'PROD1',
        descricao: 'Item',
        ncm: '00000000',
        cfop: '5102',
        cstIcms: '00',
        quantidade: 1.0,
        unidade: 'UN',
        precoUnitario: precoTotal,
        precoTotal: precoTotal,
        aliqIcms: 0,
        vlIcms: 0,
        aliqPis: 0,
        vlPis: 0,
        aliqCofins: 0,
        vlCofins: 0,
      );
    }

    testWidgets('Formata valores monetários corretamente em PT-BR',
        (WidgetTester tester) async {
      final items = [itemComTotal(1234.56)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: items,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('R\$ 1.234,56'), findsOneWidget,
          reason: 'Valor deve estar formatado como 1.234,56 (pt_BR)');
    });

    testWidgets('Formata valores pequenos sem separador de milhares',
        (WidgetTester tester) async {
      final items = [itemComTotal(100.00)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: items,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('R\$ 100,00'), findsOneWidget,
          reason: 'Valor 100.00 deve ser formatado como 100,00');
    });

    testWidgets('Formata valores grandes com múltiplos separadores de milhares',
        (WidgetTester tester) async {
      final items = [itemComTotal(1234567.89)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: items,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('R\$ 1.234.567,89'), findsOneWidget,
          reason: 'Valor grande deve incluir múltiplos separadores de milhares');
    });

    testWidgets('Formata zero corretamente', (WidgetTester tester) async {
      final items = [itemComTotal(0.0)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: items,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('R\$ 0,00'), findsOneWidget,
          reason: 'Zero deve ser formatado como 0,00');
    });
  });
}
