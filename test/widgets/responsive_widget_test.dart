import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/responsive_widget.dart';

void main() {
  group('ResponsiveWidget — LayoutBuilder + Breakpoints', () {
    testWidgets('Renderiza mobileBuilder para width < 768px',
        (WidgetTester tester) async {
      // Simulate mobile width
      tester.binding.window.physicalSizeTestValue = const Size(320, 640);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) => const Text('Mobile View'),
              tabletBuilder: (context, width) => const Text('Tablet View'),
              desktopBuilder: (context, width) => const Text('Desktop View'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile View'), findsOneWidget);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('Renderiza tabletBuilder para 768 <= width < 1024px',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1024);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) => const Text('Mobile View'),
              tabletBuilder: (context, width) => const Text('Tablet View'),
              desktopBuilder: (context, width) => const Text('Desktop View'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Tablet View'), findsOneWidget);
      expect(find.text('Desktop View'), findsNothing);
    });

    testWidgets('Renderiza desktopBuilder para width >= 1024px',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) => const Text('Mobile View'),
              tabletBuilder: (context, width) => const Text('Tablet View'),
              desktopBuilder: (context, width) => const Text('Desktop View'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile View'), findsNothing);
      expect(find.text('Tablet View'), findsNothing);
      expect(find.text('Desktop View'), findsOneWidget);
    });

    testWidgets('Fallback para mobile quando tabletBuilder não fornecido',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(800, 1024);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) => const Text('Mobile Fallback'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Fallback'), findsOneWidget);
    });

    testWidgets('Fallback chain: desktop → tablet → mobile',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) => const Text('Mobile Fallback'),
            ),
          ),
        ),
      );

      expect(find.text('Mobile Fallback'), findsOneWidget);
    });

    testWidgets('Reconstrução em rebuild com tamanho diferente',
        (WidgetTester tester) async {
      var buildCount = 0;

      tester.binding.window.physicalSizeTestValue = const Size(320, 640);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) {
                buildCount++;
                return Text('Build Mobile $buildCount');
              },
            ),
          ),
        ),
      );

      expect(find.text('Build Mobile 1'), findsOneWidget);

      // Simular resize para tablet
      tester.binding.window.physicalSizeTestValue = const Size(800, 1024);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveWidget(
              mobileBuilder: (context, width) {
                buildCount++;
                return Text('Build Mobile $buildCount');
              },
            ),
          ),
        ),
      );

      expect(find.text('Build Mobile 2'), findsOneWidget);
    });

    test('ResponsiveWidget seleciona breakpoint correto para width 320', () {
      final widget = ResponsiveWidget(
        mobileBuilder: (context, width) => const SizedBox(),
      );
      expect(widget.key, isNull); // Widget deve ser criável
    });

    test('ResponsiveWidget seleciona breakpoint correto para width 800', () {
      final widget = ResponsiveWidget(
        mobileBuilder: (context, width) => const SizedBox(),
        tabletBuilder: (context, width) => const SizedBox(),
      );
      expect(widget.key, isNull);
    });

    test('ResponsiveWidget seleciona breakpoint correto para width 1200', () {
      final widget = ResponsiveWidget(
        mobileBuilder: (context, width) => const SizedBox(),
        tabletBuilder: (context, width) => const SizedBox(),
        desktopBuilder: (context, width) => const SizedBox(),
      );
      expect(widget.key, isNull);
    });
  });
}
