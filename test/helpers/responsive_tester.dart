import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper para testar widgets em múltiplos breakpoints
class ResponsiveTestHelper {
  static const Size mobileSize = Size(400, 800);
  static const Size tabletSize = Size(800, 1200);
  static const Size desktopSize = Size(1920, 1080);

  /// Executa teste para todos os breakpoints
  static Future<void> testAllBreakpoints(
    WidgetTester tester,
    Future<void> Function(Size size) testFn,
  ) async {
    final sizes = [mobileSize, tabletSize, desktopSize];

    for (final size in sizes) {
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = size;

      await testFn(size);
      await tester.pumpAndSettle();
    }
  }

  /// Executa teste para um breakpoint específico
  static Future<void> testForBreakpoint(
    WidgetTester tester,
    Size size,
    Future<void> Function() testFn,
  ) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = size;

    await testFn();
    await tester.pumpAndSettle();
  }
}
