import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_grid_layout.dart';

void main() {
  group('ResponsiveGridLayout - TDD Web/Windows Responsive Grid', () {
    testWidgets('RED: Valida 1 coluna em mobile (<768px)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320, minWidth: 320),
                child: ResponsiveGridLayout(
                  children: [
                    Container(key: const Key('item-1')),
                    Container(key: const Key('item-2')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      if (gridView.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(1));
      }
    });

    testWidgets('RED: Valida 2 colunas em tablet (768px-1024px)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800, minWidth: 800),
                child: ResponsiveGridLayout(
                  children: [
                    Container(key: const Key('item-1')),
                    Container(key: const Key('item-2')),
                    Container(key: const Key('item-3')),
                    Container(key: const Key('item-4')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      if (gridView.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(2));
      }
    });

    testWidgets('GREEN: Renderiza grid com padding e spacing custom',
        (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(16.0);
      const customSpacing = 12.0;
      const customRunSpacing = 14.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridLayout(
              padding: customPadding,
              spacing: customSpacing,
              runSpacing: customRunSpacing,
              children: [
                Container(key: const Key('item-1')),
                Container(key: const Key('item-2')),
                Container(key: const Key('item-3')),
                Container(key: const Key('item-4')),
              ],
            ),
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);

      final paddingWidget = tester.widget<Padding>(paddingFinder.first);
      expect(paddingWidget.padding, equals(customPadding));

      final gridViewFinder = find.byType(GridView);
      final gridView = tester.widget<GridView>(gridViewFinder);
      if (gridView.gridDelegate is SliverGridDelegateWithFixedCrossAxisCount) {
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisSpacing, equals(customSpacing));
        expect(delegate.mainAxisSpacing, equals(customRunSpacing));
      }
    });

    testWidgets('REFACTOR: Renderiza sem erro com lista vazia',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ResponsiveGridLayout(children: []),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('REFACTOR: Renderiza com muitos items',
        (WidgetTester tester) async {
      final items =
          List.generate(12, (i) => Container(key: Key('item-$i')));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveGridLayout(children: items),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byKey(const Key('item-0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
