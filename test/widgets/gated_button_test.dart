// test/widgets/gated_button_test.dart
//
// Testes do widget GatedButton — condicional que mostra/oculta seu child
// baseado em um flag de habilitação. Usado para ocultar botões de ações
// que não se aplicam ao estado atual (ex.: "Editar" desaparece quando
// o pedido não está em RASCUNHO).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/gated_button.dart';

void main() {
  group('GatedButton', () {
    testWidgets('mostra child quando enabled=true', (WidgetTester tester) async {
      const testKey = Key('test_child');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatedButton(
              enabled: true,
              child: Container(
                key: testKey,
                width: 100,
                height: 50,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('oculta child quando enabled=false', (WidgetTester tester) async {
      const testKey = Key('test_child');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatedButton(
              enabled: false,
              child: Container(
                key: testKey,
                width: 100,
                height: 50,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(testKey), findsNothing);
    });

    testWidgets('reconstrói quando enabled muda de false para true', (WidgetTester tester) async {
      const testKey = Key('test_child');
      bool enabled = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GatedButton(
                    enabled: enabled,
                    child: Container(
                      key: testKey,
                      width: 100,
                      height: 50,
                      color: Colors.red,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => enabled = true),
                    child: const Text('Toggle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(testKey), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GatedButton(
                    enabled: enabled,
                    child: Container(
                      key: testKey,
                      width: 100,
                      height: 50,
                      color: Colors.red,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => enabled = true),
                    child: const Text('Toggle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });
  });
}
