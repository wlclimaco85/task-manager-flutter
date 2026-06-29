import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginRole Display Tests', () {
    testWidgets('Role exibe descricao, nao chave', (WidgetTester tester) async {
      const roleDescription = 'Administrador do Sistema';
      const roleKey = 'ADMIN_ROLE';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckboxListTile(
              title: Text(roleDescription), // Should display description, not key
              subtitle: Text(roleKey),
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text(roleDescription), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });
}
