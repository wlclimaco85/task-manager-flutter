// test/screens/anamnese_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/fitness/anamnese_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('AnamneseScreen', () {
    // TEST 1: Renderiza título
    testWidgets('renderiza título "Anamnese"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AnamneseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Anamnese'), findsOneWidget);
    });

    // TEST 2: Renderiza step 1 com 3 campos
    testWidgets('renderiza step 1 com idade, altura, peso',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AnamneseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Idade'), findsOneWidget);
      expect(find.text('Altura (cm)'), findsOneWidget);
      expect(find.text('Peso (kg)'), findsOneWidget);
    });

    // TEST 3: Renderiza TextFormFields
    testWidgets('renderiza TextFormFields para entrada de dados',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AnamneseScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    // TEST 4: Renderiza botão próximo passo
    testWidgets('renderiza botão "Próximo Passo"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AnamneseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Próximo Passo'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    // TEST 5: Renderiza step indicator (Passo 1 de 5)
    testWidgets('renderiza step indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AnamneseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Passo 1 de 5'), findsOneWidget);
    });
  });
}
