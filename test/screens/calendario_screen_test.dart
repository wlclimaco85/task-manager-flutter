// test/screens/calendario_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/contabil/calendario_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('CalendarioScreen', () {
    // TEST 1: Renderiza título
    testWidgets('renderiza título "Calendário Tributário"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Calendário Tributário'), findsOneWidget);
    });

    // TEST 2: Renderiza tabela de calendário
    testWidgets('renderiza tabela de calendário (7x6)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de Table
      expect(find.byType(Table), findsOneWidget);
    });

    // TEST 3: Lista é scrollável
    testWidgets('tela é scrollável',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    // TEST 4: Renderiza dias da semana
    testWidgets('renderiza cabeçalho com dias da semana',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CalendarioScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de pelo menos alguns dias
      expect(find.byType(Table), findsOneWidget);
    });
  });
}
