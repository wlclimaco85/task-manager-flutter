import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

void main() {
  group('ResponsiveWidget — Breakpoint Logic', () {
    testWidgets('Renderiza mobileBuilder quando width < 768',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 640,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) => const Text('Mobile'),
                tabletBuilder: (context, width) => const Text('Tablet'),
                desktopBuilder: (context, width) => const Text('Desktop'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mobile'), findsWidgets);
    });

    testWidgets('Renderiza tabletBuilder quando 768 <= width < 1024',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 800,
              height: 1024,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) => const Text('Mobile'),
                tabletBuilder: (context, width) => const Text('Tablet'),
                desktopBuilder: (context, width) => const Text('Desktop'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tablet'), findsWidgets);
    });

    testWidgets('Fallback para mobile quando tabletBuilder não fornecido',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 800,
              height: 1024,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) => const Text('Mobile Fallback'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Fallback'), findsWidgets);
    });

    testWidgets('Fallback chain: desktop → tablet → mobile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 1200,
              height: 800,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) => const Text('Mobile Base'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Base'), findsWidgets);
    });

    testWidgets('Widget renderiza sem erro quando width é válido',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 500,
              height: 640,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) =>
                    Text('Width: ${width.toStringAsFixed(0)}'),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Width:'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Suporta múltiplos rebuilds sem erro', (WidgetTester tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 500,
              height: 640,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) {
                  buildCount++;
                  return Text('Build $buildCount');
                },
              ),
            ),
          ),
        ),
      );

      int firstBuildCount = buildCount;
      expect(firstBuildCount, greaterThan(0));

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 500,
              height: 640,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) {
                  buildCount++;
                  return Text('Build $buildCount');
                },
              ),
            ),
          ),
        ),
      );

      expect(buildCount, greaterThan(firstBuildCount));
    });

    testWidgets('Renderiza corretamente com todos os três builders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 768,
              height: 1024,
              child: ResponsiveWidget(
                mobileBuilder: (context, width) => const Text('M'),
                tabletBuilder: (context, width) => const Text('T'),
                desktopBuilder: (context, width) => const Text('D'),
              ),
            ),
          ),
        ),
      );

      // 768 deve ser tablet (>= 768 e < 1024)
      expect(find.text('T'), findsWidgets);
    });

    test('ResponsiveWidget construível sem erros', () {
      expect(
        () => ResponsiveWidget(
          mobileBuilder: (context, width) => const SizedBox(),
        ),
        returnsNormally,
      );
    });
  });
}
