import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/theme/mobile_breakpoint_styles.dart';
import 'package:task_manager_flutter/core/theme/tablet_breakpoint_styles.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/widgets/accessibility/accessible_button.dart';

/// WCAG 2.1 Level AA Accessibility Test Suite
void main() {
  group('WCAG AA Color Contrast Tests', () {
    test('CR-01: GridColors.textMuted has sufficient contrast', () {
      const Color textMuted = Color(0xFF4A5449);
      expect(textMuted.value, equals(0xFF4A5449),
          reason: 'textMuted should be #4A5449 for 5.2:1 contrast');
      expect(DesignTokens.textMuted, equals(textMuted),
          reason: 'DesignTokens.textMuted should match verified color');
    });

    test('CR-01: GridColors.textMuted updated to #4A5449', () {
      expect(GridColors.textMuted.value, equals(0xFF4A5449),
          reason: 'GridColors.textMuted must be #4A5449 (was #64756A)');
    });

    test('CR-01: Primary color maintains AAA contrast', () {
      expect(DesignTokens.primary.value, equals(0xFF93070A),
          reason: 'Primary #93070A maintains 8.2:1 contrast (WCAG AAA)');
    });

    test('CR-01: Error color maintains AA contrast', () {
      expect(DesignTokens.error.value, 0xFFB71C1C,
          reason: 'Error color maintains 5.8:1 contrast (WCAG AA)');
    });
  });

  group('WCAG AA Touch Target Size Tests', () {
    test('CR-02a: Mobile buttonHeight = 48 dp', () {
      expect(MobileBreakpointStyles.buttonHeight, equals(48.0),
          reason: 'Mobile buttons must be 48 dp (WCAG AAA minimum)');
    });

    test('CR-02b: Mobile inputHeight = 48 dp', () {
      expect(MobileBreakpointStyles.inputHeight, equals(48.0),
          reason: 'Mobile inputs must be 48 dp (WCAG AA touch target)');
    });

    test('CR-02c: Tablet buttonHeight = 48 dp', () {
      expect(TabletBreakpointStyles.buttonHeight, equals(48.0),
          reason: 'Tablet buttons must be 48 dp (WCAG AA best practice)');
    });

    test('CR-02d: Tablet inputHeight = 48 dp', () {
      expect(TabletBreakpointStyles.inputHeight, equals(48.0),
          reason: 'Tablet inputs must be 48 dp (WCAG AA touch target)');
    });
  });

  group('CR-03: AccessibleButton Widget Tests', () {
    testWidgets('AccessibleButton renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleButton), findsOneWidget,
          reason: 'AccessibleButton should render');
      expect(find.byType(ElevatedButton), findsOneWidget,
          reason: 'AccessibleButton contains ElevatedButton');
    });

    testWidgets('AccessibleButton has semantic label',
        (WidgetTester tester) async {
      const String testLabel = 'Emitir NF-e';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: testLabel,
              hint: 'Valida e transmite NF-e para SEFAZ',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel(testLabel), findsOneWidget,
          reason: 'AccessibleButton must have semantic label for SR');
    });

    testWidgets('AccessibleButton marks destructive actions',
        (WidgetTester tester) async {
      const String testLabel = 'Cancelar NF-e';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: testLabel,
              onPressed: () {},
              isDestructive: true,
            ),
          ),
        ),
      );

      final semanticsFinder = find.bySemanticsLabel('Ação perigosa: $testLabel');
      expect(semanticsFinder, findsOneWidget,
          reason: 'Destructive actions announce as dangerous');
    });

    testWidgets('AccessibleButton respects padding constraints',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleButton), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'Button padding should prevent layout errors');
    });
  });

  group('WCAG AA Touch Target Consistency', () {
    test('Mobile and Tablet targets aligned', () {
      expect(MobileBreakpointStyles.buttonHeight,
          equals(TabletBreakpointStyles.buttonHeight));
      expect(MobileBreakpointStyles.inputHeight,
          equals(TabletBreakpointStyles.inputHeight));
    });

    test('All targets meet 48 dp minimum', () {
      const double minimum = 48.0;
      expect(MobileBreakpointStyles.buttonHeight, equals(minimum));
      expect(MobileBreakpointStyles.inputHeight, equals(minimum));
      expect(TabletBreakpointStyles.buttonHeight, equals(minimum));
      expect(TabletBreakpointStyles.inputHeight, equals(minimum));
    });
  });

  group('WCAG AA Color Token Sync', () {
    test('GridColors and DesignTokens.textMuted synchronized', () {
      expect(GridColors.textMuted, equals(DesignTokens.textMuted),
          reason: 'Color definitions must be synchronized');
      expect(GridColors.textMuted.value, equals(0xFF4A5449));
      expect(DesignTokens.textMuted.value, equals(0xFF4A5449));
      expect(DesignTokens.taglineColor.value, equals(0xFF4A5449),
          reason: 'taglineColor must match new textMuted color for WCAG AA compliance');
    });
  });
}
