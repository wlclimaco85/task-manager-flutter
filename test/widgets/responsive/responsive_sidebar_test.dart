import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_sidebar.dart';

void main() {
  group('ResponsiveSidebar', () {
    testWidgets('Renderiza sidebar hidden no mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 640,
              child: ResponsiveSidebar(
                items: [
                  ListTile(title: const Text('Item 1'), onTap: () {}),
                  ListTile(title: const Text('Item 2'), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza sidebar collapsible no tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 800,
              height: 1024,
              child: ResponsiveSidebar(
                items: [
                  ListTile(title: const Text('Item 1'), onTap: () {}),
                  ListTile(title: const Text('Item 2'), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza sidebar permanente no desktop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 1200,
              height: 800,
              child: ResponsiveSidebar(
                items: [
                  ListTile(title: const Text('Item 1'), onTap: () {}),
                  ListTile(title: const Text('Item 2'), onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Suporta header customizado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: ResponsiveSidebar(
                header: const Text('Header'),
                items: [ListTile(title: const Text('Item'), onTap: () {})],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Suporta footer customizado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 600,
              child: ResponsiveSidebar(
                footer: const Text('Footer'),
                items: [ListTile(title: const Text('Item'), onTap: () {})],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('ResponsiveSidebar construível sem erros', () {
      expect(
        () => ResponsiveSidebar(
          items: [ListTile(title: const Text('Item'), onTap: () {})],
        ),
        returnsNormally,
      );
    });
  });
}
