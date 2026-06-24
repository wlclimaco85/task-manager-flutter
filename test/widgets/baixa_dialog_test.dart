import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaixaDialog - validacao de valor', () {
    testWidgets('validador rejeita valor vazio', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => AlertDialog(
                  content: TextFormField(
                    key: const Key('valorField'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe o valor';
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Valor invalido';
                      return null;
                    },
                  ),
                  actions: [
                    TextButton(
                      key: const Key('confirmarBtn'),
                      onPressed: () {},
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
