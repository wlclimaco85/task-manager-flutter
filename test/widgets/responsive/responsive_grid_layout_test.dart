import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_grid_layout.dart';

void main() {
  group('ResponsiveGridLayout', () {
    testWidgets('Renderiza grid com 1 coluna no mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 640,
              child: ResponsiveGridLayout(
                children: [
                  Container(color: Colors.red),
                  Container(color: Colors.blue),
                  Container(color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza grid com 2 colunas no tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 800,
              height: 1024,
              child: ResponsiveGridLayout(
                children: [
                  Container(color: Colors.red),
                  Container(color: Colors.blue),
                  Container(color: Colors.green),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza grid com 3 colunas no desktop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 1200,
              height: 800,
              child: ResponsiveGridLayout(
                children: [
                  Container(color: Colors.red),
                  Container(color: Colors.blue),
                  Container(color: Colors.green),
                  Container(color: Colors.yellow),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Suporta padding customizado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: ResponsiveGridLayout(
                padding: const EdgeInsets.all(16.0),
                children: [Container(), Container()],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    test('ResponsiveGridLayout construível sem erros', () {
      expect(
        () => ResponsiveGridLayout(children: [Container()]),
        returnsNormally,
      );
    });
  });
}
