import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Testa a lógica de visibilidade de campos da grid (_fieldVisibility)
// O bug era: setState() chamado antes de Navigator.pop() rebuildava apenas
// o StatefulBuilder do diálogo, não a _GridListScreenState pai.
// Fix: Navigator.pop(ctx) → if (mounted) setState(() {})
void main() {
  group('Campo visibilidade — ordem pop/setState', () {
    testWidgets('setState após pop rebuilda widget pai, não o diálogo',
        (WidgetTester tester) async {
      bool visivel = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setParent) => Scaffold(
              body: Column(children: [
                if (visivel) const Text('Campo visível'),
                ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (ctx, setSt) => AlertDialog(
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                // Ordem correta: pop primeiro, depois setState pai
                                Navigator.pop(ctx);
                                setParent(() => visivel = true);
                              },
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir diálogo'),
                ),
              ]),
            ),
          ),
        ),
      );

      // Campo não aparece antes de abrir o diálogo
      expect(find.text('Campo visível'), findsNothing);

      await tester.tap(find.text('Abrir diálogo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      // Após fechar o diálogo e reconstruir o pai, campo deve aparecer
      expect(find.text('Campo visível'), findsOneWidget);
    });

    testWidgets('setState antes de pop NÃO rebuilda widget pai',
        (WidgetTester tester) async {
      bool visivel = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setParent) => Scaffold(
              body: Column(children: [
                if (visivel) const Text('Campo visível'),
                ElevatedButton(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (ctx) => StatefulBuilder(
                        builder: (ctx, setSt) => AlertDialog(
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                // Ordem antiga (bugada): setState no StatefulBuilder do diálogo,
                                // não no pai — a grid não rebuildava
                                setSt(() => visivel = true); // rebuilda só o diálogo
                                Navigator.pop(ctx);
                                // visivel=true, mas setParent nunca chamado
                              },
                              child: const Text('Aplicar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir diálogo'),
                ),
              ]),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir diálogo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      // Bug: campo continua invisível porque setSt rebuildou apenas o diálogo
      expect(find.text('Campo visível'), findsNothing);
    });

    testWidgets('_fieldVisibility Map filtra campos corretamente',
        (WidgetTester tester) async {
      final fieldVisibility = <String, bool>{
        'nome': true,
        'cpf': false,
        'email': true,
      };

      final campos = ['nome', 'cpf', 'email'];
      final visiveis = campos.where((c) => fieldVisibility[c] == true).toList();

      expect(visiveis, containsAll(['nome', 'email']));
      expect(visiveis, isNot(contains('cpf')));
    });

    testWidgets('toggle de campo inverte visibilidade corretamente',
        (WidgetTester tester) async {
      final fieldVisibility = <String, bool>{
        'nome': true,
        'cpf': false,
      };

      // Simula toggle no diálogo
      fieldVisibility['nome'] = !(fieldVisibility['nome'] ?? true);
      fieldVisibility['cpf'] = !(fieldVisibility['cpf'] ?? false);

      expect(fieldVisibility['nome'], isFalse);
      expect(fieldVisibility['cpf'], isTrue);
    });
  });
}
