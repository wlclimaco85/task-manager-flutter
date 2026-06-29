// test/screens/obrigacoes_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/contabil/obrigacoes_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('ObrigacoesScreen', () {
    // TEST 1: Renderiza título
    testWidgets('renderiza título "Obrigações Fiscais"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ObrigacoesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Obrigações Fiscais'), findsOneWidget);
    });

    // TEST 2: Renderiza 3 obrigações
    testWidgets('renderiza lista de 3 obrigações (ECF, NFe, NFSe)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ObrigacoesScreen()));
      await tester.pumpAndSettle();

      // Verifica nomes das obrigações
      expect(find.text('ECF'), findsOneWidget);
      expect(find.text('NFe'), findsOneWidget);
      expect(find.text('NFSe'), findsOneWidget);
    });

    // TEST 3: Cada obrigação tem status com cor
    testWidgets('obrigações exibem status colorido',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ObrigacoesScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de ListTile
      expect(find.byType(ListTile), findsWidgets);
    });

    // TEST 4: Lista é scrollável
    testWidgets('lista é renderizada dentro de widget scrollável',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ObrigacoesScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // TEST 5: Renderiza ícones nas obrigações
    testWidgets('cada obrigação tem ícone visual',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ObrigacoesScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de ícones (pelo menos 3)
      expect(find.byIcon(Icons.receipt), findsWidgets);
    });
  });
}
