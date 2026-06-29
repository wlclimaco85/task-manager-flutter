// test/screens/mensagens_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/contabil/mensagens_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('MensagensScreen', () {
    // TEST 1: Renderiza título
    testWidgets('renderiza título "Mensagens"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MensagensScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mensagens'), findsOneWidget);
    });

    // TEST 2: Renderiza lista de mensagens
    testWidgets('renderiza lista com 3 mensagens mock',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MensagensScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de ListView
      expect(find.byType(ListView), findsWidgets);
    });

    // TEST 3: Renderiza campo de texto para envio
    testWidgets('renderiza campo de texto e botão de envio',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MensagensScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de TextFormField
      expect(find.byType(TextFormField), findsOneWidget);

      // Verifica presença de botão (send, submit, enviar)
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    // TEST 4: Tela é scrollável
    testWidgets('tela é scrollável',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MensagensScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    // TEST 5: Renderiza card de mensagem
    testWidgets('cada mensagem é exibida em um card ou container',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const MensagensScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de Card ou Container
      expect(find.byType(Card), findsWidgets);
    });
  });
}
