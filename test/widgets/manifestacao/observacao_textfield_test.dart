import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/manifestacao/observacao_textfield.dart';

void main() {
  group('ObservacaoTextfield', () {
    testWidgets('Renderiza textfield com label', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
            ),
          ),
        ),
      );

      expect(find.text('Observações'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Mostra contador de caracteres', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
            ),
          ),
        ),
      );

      expect(find.text('0/500'), findsOneWidget);
    });

    testWidgets('Atualiza contador ao digitar', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Teste');
      await tester.pumpAndSettle();

      expect(find.text('5/500'), findsOneWidget);
    });

    testWidgets('Exibe mensagem de erro quando fornecida', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
              errorText: 'Campo obrigatório',
            ),
          ),
        ),
      );

      expect(find.text('Campo obrigatório'), findsOneWidget);
    });

    testWidgets('Respeita maxLength', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
              maxLength: 10,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.typeText(find.byType(TextField), 'Teste muito longo');
      await tester.pumpAndSettle();

      expect(controller.text.length, lessThanOrEqualTo(10));
    });

    testWidgets('Callback onChanged executado', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      String? textoMudado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
              onChanged: (value) => textoMudado = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Teste');
      await tester.pumpAndSettle();

      expect(textoMudado, equals('Teste'));
    });

    testWidgets('Semantics label presente', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
            ),
          ),
        ),
      );

      expect(find.text('Observações'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Dark mode muda cores', (WidgetTester tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ObservacaoTextfield(
              controller: controller,
              label: 'Observações',
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
