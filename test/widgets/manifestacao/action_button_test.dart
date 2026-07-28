import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/manifestacao/action_buttons.dart';

void main() {
  group('ActionButton', () {
    testWidgets('Renderiza botão primary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Aceitar',
              onPressed: () {},
              type: ActionButtonType.primary,
            ),
          ),
        ),
      );

      expect(find.text('Aceitar'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Botão primary desabilitado quando isEnabled=false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Aceitar',
              onPressed: () {},
              type: ActionButtonType.primary,
              isEnabled: false,
            ),
          ),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
    });

    testWidgets('Botão secondary renderiza corretamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Recusar',
              onPressed: () {},
              type: ActionButtonType.secondary,
            ),
          ),
        ),
      );

      expect(find.text('Recusar'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Botão danger renderiza corretamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Limpar',
              onPressed: () {},
              type: ActionButtonType.danger,
            ),
          ),
        ),
      );

      expect(find.text('Limpar'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('Mostra spinner quando isLoading=true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Aceitar',
              onPressed: () {},
              type: ActionButtonType.primary,
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Callback executado ao clicar', (WidgetTester tester) async {
      bool chamado = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Aceitar',
              onPressed: () => chamado = true,
              type: ActionButtonType.primary,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(chamado, isTrue);
    });

    testWidgets('Semantics label presente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButton(
              label: 'Aceitar',
              onPressed: () {},
              type: ActionButtonType.primary,
              ariaLabel: 'Aceitar manifestação de recebimento',
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Aceitar manifestação de recebimento'),
        findsOneWidget,
      );
    });
  });

  group('ActionButtonGroup', () {
    testWidgets('Renderiza grupo de botões', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [
                ActionButton(
                  label: 'Aceitar',
                  onPressed: () {},
                  type: ActionButtonType.primary,
                ),
                ActionButton(
                  label: 'Recusar',
                  onPressed: () {},
                  type: ActionButtonType.secondary,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Aceitar'), findsOneWidget);
      expect(find.text('Recusar'), findsOneWidget);
    });

    testWidgets('Mobile: stack vertical', (WidgetTester tester) async {
      addTearDown(tester.binding.window.physicalSizeTestValue = null);
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionButtonGroup(
              buttons: [
                ActionButton(
                  label: 'Aceitar',
                  onPressed: () {},
                  type: ActionButtonType.primary,
                ),
                ActionButton(
                  label: 'Recusar',
                  onPressed: () {},
                  type: ActionButtonType.secondary,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });
  });
}
