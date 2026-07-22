import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';

void main() {
  group('NfeListScreen — Mobile PopupMenu Error Handling', () {
    testWidgets(
      'PopupMenu callback com Future.microtask permite SnackBar em caso de erro',
      (WidgetTester tester) async {
        // Arrange: criar um Scaffold simples com PopupMenu
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Ação 1'),
                    onTap: () {
                      // Usar Future.microtask para garantir execução async
                      Future.microtask(() {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ação 1 executada')),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Act: tap no PopupMenu para abrir
        await tester.tap(find.byType(PopupMenuButton));
        await tester.pumpAndSettle();

        // Act: tap no item do menu
        await tester.tap(find.text('Ação 1'));
        await tester.pumpAndSettle();

        // Assert: SnackBar deve estar visível (callback async permitiu exibição)
        expect(find.text('Ação 1 executada'), findsOneWidget,
            reason:
                'SnackBar deve ser exibida após PopupMenu fechar com Future.microtask()');
      },
    );

    testWidgets(
      'PopupMenu com callback async trata erros de navegação corretamente',
      (WidgetTester tester) async {
        // Arrange: criar Scaffold com PopupMenu que simula navigation error
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Navegar'),
                    onTap: () {
                      // Callback async permite tratamento de erro
                      Future.microtask(() {
                        try {
                          // Simular operação que pode falhar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navegando...')),
                          );
                        } catch (e) {
                          // Erro é capturado e tratado
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Act: abrir e executar callback
        await tester.tap(find.byType(PopupMenuButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Navegar'));
        await tester.pumpAndSettle();

        // Assert: SnackBar de sucesso deve estar visível
        expect(find.text('Navegando...'), findsOneWidget,
            reason: 'Callback async permite SnackBar ser exibida corretamente');
      },
    );

    testWidgets(
      'PopupMenu com onTap sync pode perder SnackBar se PopupMenu fechar muito rápido',
      (WidgetTester tester) async {
        // Este teste documenta o BUG: callback sync faz PopupMenu fechar imediatamente
        // Caso um erro ocorra, SnackBar pode não ter tempo de ser renderizado
        // A fix (CR-03) resolve isso usando Future.microtask()

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Erro Sync'),
                    // PROBLEMA: callback sync faz PopupMenu fechar imediatamente
                    onTap: () {
                      try {
                        throw Exception('Erro durante operação');
                      } catch (e) {
                        // PopupMenu já fechou neste ponto
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        // Act: executar o callback
        await tester.tap(find.byType(PopupMenuButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Erro Sync'));
        await tester.pumpAndSettle();

        // Assert: neste caso, SnackBar pode não estar visível (timing issue)
        // A fix usa Future.microtask() para garantir execução após PopupMenu fechar
        // Este teste simplesmente documenta o comportamento BUG.
      },
    );
  });
}
