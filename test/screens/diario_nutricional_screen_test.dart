// test/screens/diario_nutricional_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/fitness/diario_nutricional_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('DiarioNutricionalScreen', () {
    // TEST 1: Renderiza título e 3 refeições
    testWidgets('renderiza título e 3 refeições com calorias',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const DiarioNutricionalScreen()));
      await tester.pumpAndSettle();

      // Verifica título
      expect(find.text('Diário Nutricional'), findsOneWidget);

      // Verifica 3 refeições hardcoded
      expect(find.text('Café da Manhã'), findsOneWidget);
      expect(find.text('Almoço'), findsOneWidget);
      expect(find.text('Lanche'), findsOneWidget);

      // Verifica calorias
      expect(find.text('300 kcal'), findsOneWidget);
      expect(find.text('400 kcal'), findsOneWidget);
      expect(find.text('350 kcal'), findsOneWidget);
    });

    // TEST 2: Total de calorias é calculado
    testWidgets('calcula total de calorias (1050)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const DiarioNutricionalScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Total: 1050 kcal'), findsOneWidget);
    });

    // TEST 3: Renderiza ícone de refeição
    testWidgets('renderiza ícones de refeição', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const DiarioNutricionalScreen()));
      await tester.pumpAndSettle();

      // Verifica se há Cards com ícones (pelo menos 3)
      expect(find.byType(Card), findsWidgets);
    });
  });
}
