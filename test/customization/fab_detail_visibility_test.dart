import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FloatingActionButton Visibility Tests', () {
    testWidgets('FAB nao aparece quando ha detailScreenBuilder', (WidgetTester tester) async {
      // Simula um Scaffold com FAB condicional (não renderiza quando detailScreenBuilder != null)
      bool hasDetailScreenBuilder = true;
      bool hasPermission = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: !hasDetailScreenBuilder && hasPermission
                ? FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  )
                : null,
            body: const Center(child: Text('Detail Screen')),
          ),
        ),
      );

      // FAB não deveria existir quando detailScreenBuilder é definido
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('FAB aparece quando nao ha detailScreenBuilder', (WidgetTester tester) async {
      bool hasDetailScreenBuilder = false;
      bool hasPermission = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: !hasDetailScreenBuilder && hasPermission
                ? FloatingActionButton(
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  )
                : null,
            body: const Center(child: Text('List Screen')),
          ),
        ),
      );

      // FAB deveria existir quando em modo lista
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
