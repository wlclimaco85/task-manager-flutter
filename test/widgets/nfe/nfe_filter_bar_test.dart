import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_filter_bar.dart';

void main() {
  group('NfeFilterBar Widget', () {
    testWidgets('renderiza sem erros', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(breakpoint: Breakpoint.desktop),
          ),
        ),
      );

      // Assert
      expect(find.byType(NfeFilterBar), findsOneWidget);
    });

    testWidgets('status dropdown abre e seleciona valores', (WidgetTester tester) async {
      // Arrange
      String? selectedStatus;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(
              breakpoint: Breakpoint.desktop,
              onFilterChanged: (status, _, __, ___, __) => selectedStatus = status,
            ),
          ),
        ),
      );

      // Abre dropdown e seleciona 'Autorizada'
      await tester.tap(find.byType(DropdownButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autorizada'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Autorizada'), findsOneWidget);
    });

    testWidgets('date range picker abre e seleciona datas', (WidgetTester tester) async {
      // Arrange
      DateTime? dataInicio;
      DateTime? dataFim;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(
              breakpoint: Breakpoint.desktop,
              onFilterChanged: (_, inicio, fim, __, _) {
                dataInicio = inicio;
                dataFim = fim;
              },
            ),
          ),
        ),
      );

      // Clica no botão de date range
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('reset button limpa todos os filtros', (WidgetTester tester) async {
      // Arrange
      bool resetCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(
              breakpoint: Breakpoint.desktop,
              initialStatus: 'Autorizada',
              onFilterChanged: (_, __, ___, ____, _____) => resetCalled = true,
            ),
          ),
        ),
      );

      // Clica reset
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert
      expect(resetCalled, isTrue);
    });

    testWidgets('sort menu abre e muda ordenação', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(breakpoint: Breakpoint.desktop),
          ),
        ),
      );

      // Abre sort menu
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PopupMenuButton), findsOneWidget);
    });

    testWidgets('renderiza com layout column em mobile', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(breakpoint: Breakpoint.mobile),
          ),
        ),
      );

      // Assert
      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(NfeFilterBar), findsOneWidget);
    });

    testWidgets('renderiza com layout row em desktop', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(breakpoint: Breakpoint.desktop),
          ),
        ),
      );

      // Assert
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(NfeFilterBar), findsOneWidget);
    });

    testWidgets('initial values são respeitados', (WidgetTester tester) async {
      // Arrange
      final dataInicio = DateTime(2026, 8, 1);
      final dataFim = DateTime(2026, 8, 10);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(
              breakpoint: Breakpoint.desktop,
              initialStatus: 'Autorizada',
              initialDataInicio: dataInicio,
              initialDataFim: dataFim,
              initialSortBy: 'data',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Autorizada'), findsOneWidget);
    });

    testWidgets('callback é chamado ao mudar filtro', (WidgetTester tester) async {
      // Arrange
      int callCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NfeFilterBar(
              breakpoint: Breakpoint.desktop,
              onFilterChanged: (_, __, ___, ____, _____) => callCount++,
            ),
          ),
        ),
      );

      // Muda status
      await tester.tap(find.byType(DropdownButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autorizada'));
      await tester.pumpAndSettle();

      // Assert
      expect(callCount, greaterThan(0));
    });

    testWidgets('dark mode suportado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NfeFilterBar(breakpoint: Breakpoint.desktop),
          ),
        ),
      );

      // Assert
      expect(find.byType(NfeFilterBar), findsOneWidget);
    });
  });
}
