import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/accessibility/index.dart';

void main() {
  testWidgets('AccessibleButton executa callback ao tocar', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleButton(
            label: 'Salvar',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Salvar'));

    expect(tapped, isTrue);
  });

  testWidgets('AccessibleTextField exibe label e erro', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleTextField(
            label: 'Descricao',
            errorText: 'Campo obrigatorio',
            controller: controller,
          ),
        ),
      ),
    );

    expect(find.text('Descricao'), findsOneWidget);
    expect(find.text('Campo obrigatorio'), findsOneWidget);
  });
}
