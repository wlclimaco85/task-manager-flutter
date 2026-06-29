// test/screens/registro_carga_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/fitness/registro_carga_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('RegistroCargaScreen', () {
    // TEST 1: Renderiza título e dropdown de séries
    testWidgets('renderiza título e dropdown de séries',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const RegistroCargaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Registro de Carga'), findsOneWidget);
      expect(find.text('Série'), findsOneWidget);
    });

    // TEST 2: Renderiza campo de peso
    testWidgets('renderiza campo de peso (kg)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const RegistroCargaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Peso (kg)'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    // TEST 3: Renderiza botão salvar
    testWidgets('renderiza botão salvar',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const RegistroCargaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Salvar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

  });
}
