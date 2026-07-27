import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';

void main() {
  group('NfeItemsTable._formatCurrency', () {
    // Testamos _formatCurrency criando uma instância e acessando via reflexão
    // ou testamos indiretamente verificando o output do widget.
    // Para simplicidade, vamos fazer teste direto do método privado
    // usando a abordagem de extract-to-public ou verificar via widget rendering.

    testWidgets('Formata valores monetários corretamente em PT-BR',
        (WidgetTester tester) async {
      // Arrange: criar widget com itens conhecidos
      final items = [
        NfeItemModel(
          id: '1',
          descricao: 'Item 1',
          valor: 1234.56,
          quantidade: 1.0,
          icms: 0,
          pis: 0,
          cofins: 0,
        ),
      ];

      // Act: renderizar widget
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

      // Assert: verificar que o valor formatado está visível no widget
      // Esperamos: "1.234,56" (com ponto como separador de milhares e vírgula decimal)
      expect(find.text('R\$ 1.234,56'), findsOneWidget,
          reason: 'Valor deve estar formatado como 1.234,56 (pt_BR)');
    });

    testWidgets('Formata valores pequenos sem separador de milhares',
        (WidgetTester tester) async {
      // Arrange: valor abaixo de 1000
      final items = [
        NfeItemModel(
          id: '1',
          descricao: 'Item Pequeno',
          valor: 100.00,
          quantidade: 1.0,
          icms: 0,
          pis: 0,
          cofins: 0,
        ),
      ];

      // Act: renderizar widget
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

      // Assert: verificar formatação sem ponto de separador (apenas decimal)
      expect(find.text('R\$ 100,00'), findsOneWidget,
          reason: 'Valor 100.00 deve ser formatado como 100,00');
    });

    testWidgets('Formata valores grandes com múltiplos separadores de milhares',
        (WidgetTester tester) async {
      // Arrange: valor acima de 1 milhão
      final items = [
        NfeItemModel(
          id: '1',
          descricao: 'Item Grande',
          valor: 1234567.89,
          quantidade: 1.0,
          icms: 0,
          pis: 0,
          cofins: 0,
        ),
      ];

      // Act: renderizar widget
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

      // Assert: verificar múltiplos separadores
      expect(find.text('R\$ 1.234.567,89'), findsOneWidget,
          reason: 'Valor grande deve incluir múltiplos separadores de milhares');
    });

    testWidgets('Formata zero corretamente', (WidgetTester tester) async {
      // Arrange: valor zero
      final items = [
        NfeItemModel(
          id: '1',
          descricao: 'Item Grátis',
          valor: 0.0,
          quantidade: 1.0,
          icms: 0,
          pis: 0,
          cofins: 0,
        ),
      ];

      // Act: renderizar widget
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

      // Assert: verificar formatação de zero
      expect(find.text('R\$ 0,00'), findsOneWidget,
          reason: 'Zero deve ser formatado como 0,00');
    });
  });
}
