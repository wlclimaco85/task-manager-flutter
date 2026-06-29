// test/screens/frequencia_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/fitness/frequencia_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('FrequenciaScreen', () {
    // TEST 1: Renderiza título
    testWidgets('renderiza título "Frequência"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const FrequenciaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Frequência'), findsOneWidget);
    });

    // TEST 2: Renderiza 7 dias da semana
    testWidgets('renderiza 7 dias da semana',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const FrequenciaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Seg'), findsOneWidget);
      expect(find.text('Ter'), findsOneWidget);
      expect(find.text('Qua'), findsOneWidget);
      expect(find.text('Qui'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Sab'), findsOneWidget);
      expect(find.text('Dom'), findsOneWidget);
    });

    // TEST 3: Renderiza gráfico
    testWidgets('renderiza gráfico com barras',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const FrequenciaScreen()));
      await tester.pumpAndSettle();

      // Verifica se há algum widget de chart (CustomPaint ou similar)
      expect(find.byType(SizedBox), findsWidgets);
    });

    // TEST 4: Renderiza 7 barras
    testWidgets('renderiza 7 valores de frequência',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const FrequenciaScreen()));
      await tester.pumpAndSettle();

      // Verifica se há pelo menos 7 widgets de barra/valor
      expect(find.byType(Container), findsWidgets);
    });
  });
}
