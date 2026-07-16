import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive/responsive_button_bar.dart';

void main() {
  group('ResponsiveButtonBar', () {
    testWidgets('Renderiza buttons stacked verticalmente no mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 200,
              child: ResponsiveButtonBar(
                buttons: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza buttons horizontalmente no tablet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 800,
              height: 100,
              child: ResponsiveButtonBar(
                buttons: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renderiza buttons horizontalmente no desktop',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 1200,
              height: 100,
              child: ResponsiveButtonBar(
                buttons: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Suporta spacing customizado', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: ResponsiveButtonBar(
                spacing: 16.0,
                buttons: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    test('ResponsiveButtonBar construível sem erros', () {
      expect(
        () => ResponsiveButtonBar(
          buttons: [ElevatedButton(onPressed: () {}, child: const Text('Btn'))],
        ),
        returnsNormally,
      );
    });
  });
}
