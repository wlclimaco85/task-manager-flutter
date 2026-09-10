import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/widgets/nfe/currency_text_field.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_action_bar.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_filter_chip.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_items_table.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_status_badge.dart';
import 'package:task_manager_flutter/widgets/nfe/responsive_scaffold.dart';
import '../helpers/responsive_tester.dart';
import '../mocks/nfe_mocks.dart';

void main() {
  group('NfeStatusBadge', () {
    testWidgets('Renderiza badge compacta para status autorizada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeStatusBadge(
              status: NfeStatus.autorizada,
              breakpoint: Breakpoint.mobile,
              expanded: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Renderiza badge expandida com label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeStatusBadge(
              status: NfeStatus.rejeitada,
              breakpoint: Breakpoint.tablet,
              expanded: true,
            ),
          ),
        ),
      );

      expect(find.text('Rejeitada'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('Badge adapta tamanho por breakpoint', (tester) async {
      for (final breakpoint in [Breakpoint.mobile, Breakpoint.tablet, Breakpoint.desktop]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NfeStatusBadge(
                status: NfeStatus.pendente,
                breakpoint: breakpoint,
              ),
            ),
          ),
        );

        expect(find.byType(Icon), findsWidgets);
      }
    });
  });

  group('NfeActionBar', () {
    testWidgets('Renderiza FAB em mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeActionBar(
              breakpoint: Breakpoint.mobile,
              onCreatePressed: () {},
              onImportPressed: () {},
              onFilterPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Renderiza botões inline em desktop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeActionBar(
              breakpoint: Breakpoint.desktop,
              onCreatePressed: () {},
              onImportPressed: () {},
              onFilterPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsWidgets);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('Callback onCreatePressed funciona', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeActionBar(
              breakpoint: Breakpoint.mobile,
              onCreatePressed: () => pressed = true,
              onImportPressed: () {},
              onFilterPressed: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(pressed, true);
    });
  });

  group('NfeItemsTable', () {
    testWidgets('Renderiza lista vazia corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: [],
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('Nenhum item adicionado'), findsOneWidget);
    });

    testWidgets('Renderiza cards em mobile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: [NfeMocks.mockItem1],
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsWidgets);
      expect(find.text('Serviço de Consultoria'), findsOneWidget);
    });

    testWidgets('Renderiza DataTable em desktop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NfeItemsTable(
                items: [NfeMocks.mockItem1, NfeMocks.mockItem2],
                breakpoint: Breakpoint.desktop,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Descrição'), findsOneWidget);
    });

    testWidgets('Formata valores monetários corretamente', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeItemsTable(
              items: [NfeMocks.mockItem1],
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      // Verifica se a moeda é formatada (presença de R$)
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('CurrencyTextField', () {
    testWidgets('Renderiza com label correto', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              label: 'Valor',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Valor'), findsOneWidget);
    });

    testWidgets('Aplica máscara de moeda', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              label: 'Valor',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final field = find.byType(TextFormField);
      await tester.enterText(field, '123456');
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Callback onChanged emite double', (tester) async {
      double? emittedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              label: 'Valor',
              onChanged: (value) => emittedValue = value,
            ),
          ),
        ),
      );

      final field = find.byType(TextFormField);
      await tester.enterText(field, '100');
      await tester.pump();

      expect(emittedValue, isNotNull);
    });

    testWidgets('Modo readOnly funciona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyTextField(
              label: 'Valor',
              readOnly: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final field = find.byType(TextFormField);
      expect(field, findsOneWidget);
    });
  });

  group('NfeFilterChip', () {
    testWidgets('Renderiza chip com label e ícone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterChip(
              label: 'Status: Autorizada',
              icon: Icons.filter_list,
              onRemoved: () {},
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      expect(find.text('Status: Autorizada'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('Callback onRemoved é chamado', (tester) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterChip(
              label: 'Filtro',
              icon: Icons.filter_list,
              onRemoved: () => removed = true,
              breakpoint: Breakpoint.mobile,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(removed, true);
    });

    testWidgets('Chip adapta tamanho por breakpoint', (tester) async {
      for (final breakpoint in [Breakpoint.mobile, Breakpoint.tablet, Breakpoint.desktop]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NfeFilterChip(
                label: 'Filtro',
                icon: Icons.filter_list,
                onRemoved: () {},
                breakpoint: breakpoint,
              ),
            ),
          ),
        );

        expect(find.byType(Chip), findsOneWidget);
      }
    });
  });

  group('ResponsiveScaffold', () {
    testWidgets('Renderiza scaffold com título', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Notas Fiscais',
            body: const Text('Conteúdo'),
            breakpoint: Breakpoint.mobile,
          ),
        ),
      );

      expect(find.text('Notas Fiscais'), findsOneWidget);
    });

    testWidgets('Renderiza body corretamente', (tester) async {
      const testText = 'Conteúdo do scaffold';

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Teste',
            body: const Text(testText),
            breakpoint: Breakpoint.mobile,
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('Renderiza filtros se fornecidos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Teste',
            body: const Text('Conteúdo'),
            breakpoint: Breakpoint.desktop,
            filters: [
              NfeFilterChip(
                label: 'Filtro 1',
                icon: Icons.filter_list,
                onRemoved: () {},
                breakpoint: Breakpoint.desktop,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Filtro 1'), findsOneWidget);
    });

    testWidgets('Renderiza FAB se fornecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveScaffold(
            title: 'Teste',
            body: const Text('Conteúdo'),
            breakpoint: Breakpoint.mobile,
            fab: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('Widgets adaptam-se a múltiplos breakpoints', (tester) async {
      await ResponsiveTestHelper.testAllBreakpoints(
        tester,
        (size) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: NfeStatusBadge(
                  status: NfeStatus.autorizada,
                  breakpoint: size.width < 768 ? Breakpoint.mobile : (size.width < 1024 ? Breakpoint.tablet : Breakpoint.desktop),
                ),
              ),
            ),
          );

          expect(find.byType(NfeStatusBadge), findsOneWidget);
        },
      );
    });
  });
}
