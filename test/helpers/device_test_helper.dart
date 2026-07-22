import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper para testes de responsividade em diferentes tamanhos de dispositivo
///
/// Fornece constantes de tamanho padrão e função para pump widgets
/// com tamanho específico para testes em múltiplos breakpoints.
class DeviceTestHelper {
  // ============================================================================
  // DEVICE SIZES — Padrão do projeto
  // ============================================================================

  /// Mobile em retrato (375 x 667 px) — iPhone SE / Android standard
  static const Size mobilePortrait = Size(375, 667);

  /// Mobile em paisagem (667 x 375 px)
  static const Size mobileLandscape = Size(667, 375);

  /// Tablet em retrato (800 x 1200 px) — iPad padrão
  static const Size tabletPortrait = Size(800, 1200);

  /// Tablet em paisagem (1200 x 800 px)
  static const Size tabletLandscape = Size(1200, 800);

  /// Desktop em resolução comum (1280 x 720 px) — HD 720p
  static const Size desktopWindow = Size(1280, 720);

  /// Desktop em Full HD (1920 x 1080 px)
  static const Size desktopFullHd = Size(1920, 1080);

  /// Valores de breakpoint para verificação responsiva
  static const int breakpointMobile = 768;
  static const int breakpointTablet = 1024;

  // ============================================================================
  // PUMP FUNCTIONS
  // ============================================================================

  /// Renderiza widget com tamanho específico
  ///
  /// Exemplo:
  /// ```dart
  /// await DeviceTestHelper.pumpWidgetWithSize(
  ///   tester,
  ///   buildMyWidget(),
  ///   DeviceTestHelper.mobilePortrait,
  /// );
  /// ```
  static Future<void> pumpWidgetWithSize(
    WidgetTester tester,
    Widget widget,
    Size size,
  ) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    tester.binding.window.physicalSizeTestValue = size;

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Renderiza widget e aguarda settle (sem tamanho específico)
  static Future<void> pumpWidgetAndSettle(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  /// Renderiza widget, aplica tamanho, e simula orientação
  ///
  /// Simulates portrait and landscape rotations
  static Future<void> testBothOrientations(
    WidgetTester tester,
    Widget Function() buildWidget,
    Future<void> Function(WidgetTester, bool isPortrait) test,
  ) async {
    // Teste em retrato
    await pumpWidgetWithSize(
      tester,
      buildWidget(),
      DeviceTestHelper.mobilePortrait,
    );
    await test(tester, true);

    // Limpa state
    await tester.binding.window.clearPhysicalSizeTestValue();

    // Teste em paisagem
    await pumpWidgetWithSize(
      tester,
      buildWidget(),
      DeviceTestHelper.mobileLandscape,
    );
    await test(tester, false);
  }

  // ============================================================================
  // ASSERTION HELPERS
  // ============================================================================

  /// Verifica se widget está visível na viewport
  static bool isWidgetVisible(WidgetTester tester, Finder finder) {
    final matches = finder.evaluate();
    if (matches.isEmpty) return false;

    for (final match in matches) {
      final renderBox = match.renderObject as RenderBox?;
      if (renderBox == null) return false;

      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      // Verifica se está dentro da viewport
      if (offset.dx < 0 || offset.dy < 0) return false;
      if (offset.dx + size.width > 500 || offset.dy + size.height > 800) {
        return false;
      }
    }
    return true;
  }

  /// Aguarda widget estar visível na tela
  static Future<void> waitForWidgetVisibility(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pumpAndSettle();
      if (isWidgetVisible(tester, finder)) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    throw TimeoutException(
      'Widget não ficou visível dentro do timeout de $timeout',
    );
  }

  /// Obtém a largura atual da viewport
  static double getScreenWidth(WidgetTester tester) {
    return tester.binding.window.physicalSize.width /
        tester.binding.window.devicePixelRatio;
  }

  /// Obtém a altura atual da viewport
  static double getScreenHeight(WidgetTester tester) {
    return tester.binding.window.physicalSize.height /
        tester.binding.window.devicePixelRatio;
  }

  // ============================================================================
  // BREAKPOINT HELPERS
  // ============================================================================

  /// Retorna true se largura é mobile (<768px)
  static bool isMobileWidth(double width) => width < breakpointMobile;

  /// Retorna true se largura é tablet (768-1024px)
  static bool isTabletWidth(double width) =>
      width >= breakpointMobile && width < breakpointTablet;

  /// Retorna true se largura é desktop (>=1024px)
  static bool isDesktopWidth(double width) => width >= breakpointTablet;

  /// Retorna nome legível do breakpoint
  static String getBreakpointName(double width) {
    if (isMobileWidth(width)) return 'mobile';
    if (isTabletWidth(width)) return 'tablet';
    return 'desktop';
  }

  // ============================================================================
  // SCROLL HELPERS
  // ============================================================================

  /// Desliza para cima em uma ListView/ScrollView
  static Future<void> scrollUp(WidgetTester tester, {int steps = 5}) async {
    for (int i = 0; i < steps; i++) {
      await tester.scroll(
        find.byType(ListView),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Desliza para baixo em uma ListView/ScrollView
  static Future<void> scrollDown(WidgetTester tester, {int steps = 5}) async {
    for (int i = 0; i < steps; i++) {
      await tester.scroll(
        find.byType(ListView),
        const Offset(0, 100),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Desliza para direita em uma ListView horizontal
  static Future<void> scrollRight(WidgetTester tester, {int steps = 5}) async {
    for (int i = 0; i < steps; i++) {
      await tester.scroll(
        find.byType(ListView),
        const Offset(100, 0),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Desliza para esquerda em uma ListView horizontal
  static Future<void> scrollLeft(WidgetTester tester, {int steps = 5}) async {
    for (int i = 0; i < steps; i++) {
      await tester.scroll(
        find.byType(ListView),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();
    }
  }

  // ============================================================================
  // GESTURE HELPERS
  // ============================================================================

  /// Simula long press em widget
  static Future<void> longPress(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }

  /// Simula double tap em widget
  static Future<void> doubleTap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Simula drag (arrastar) widget
  static Future<void> drag(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }

  /// Simula swipe rápido
  static Future<void> swipe(
    WidgetTester tester,
    Finder finder,
    Offset direction,
  ) async {
    await tester.fling(finder, direction, 500);
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // INPUT HELPERS
  // ============================================================================

  /// Digita texto em TextField
  static Future<void> typeText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.pump();
  }

  /// Limpa TextField
  static Future<void> clearTextField(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, '');
    await tester.pump();
  }

  /// Seleciona opção em Dropdown
  static Future<void> selectDropdownOption(
    WidgetTester tester,
    Finder dropdownFinder,
    String optionText,
  ) async {
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final optionFinder = find.text(optionText);
    expect(optionFinder, findsOneWidget);

    await tester.tap(optionFinder);
    await tester.pumpAndSettle();
  }

  // ============================================================================
  // SCREENSHOT & DEBUGGING
  // ============================================================================

  /// Imprime tamanho atual da viewport (útil para debug)
  static void printScreenSize(WidgetTester tester) {
    final width = getScreenWidth(tester);
    final height = getScreenHeight(tester);
    final breakpoint = getBreakpointName(width);

    print('[DeviceTestHelper] Screen: ${width.toStringAsFixed(0)} x '
        '${height.toStringAsFixed(0)}px ($breakpoint)');
  }

  /// Renderiza widget e retorna descrição de estado (para debug)
  static String describeWidget(WidgetTester tester, Finder finder) {
    final matches = finder.evaluate();
    if (matches.isEmpty) return 'Widget not found';

    final buffer = StringBuffer();
    for (int i = 0; i < matches.length; i++) {
      final widget = matches.elementAt(i).widget;
      buffer.writeln('[$i] ${widget.runtimeType}: ${widget.key}');
    }
    return buffer.toString();
  }
}

// ============================================================================
// HELPERS PARA VERIFICAÇÃO DE LAYOUT
// ============================================================================

/// Verifica se múltiplos widgets estão alinhados horizontalmente
bool areWidgetsAlignedHorizontally(WidgetTester tester, List<Finder> finders) {
  if (finders.isEmpty) return false;

  double? expectedY;
  for (final finder in finders) {
    final matches = finder.evaluate();
    if (matches.isEmpty) return false;

    final renderBox = matches.first.renderObject as RenderBox?;
    if (renderBox == null) return false;

    final y = renderBox.localToGlobal(Offset.zero).dy;
    if (expectedY == null) {
      expectedY = y;
    } else if ((y - expectedY).abs() > 5) {
      return false;
    }
  }
  return true;
}

/// Verifica se múltiplos widgets estão alinhados verticalmente
bool areWidgetsAlignedVertically(WidgetTester tester, List<Finder> finders) {
  if (finders.isEmpty) return false;

  double? expectedX;
  for (final finder in finders) {
    final matches = finder.evaluate();
    if (matches.isEmpty) return false;

    final renderBox = matches.first.renderObject as RenderBox?;
    if (renderBox == null) return false;

    final x = renderBox.localToGlobal(Offset.zero).dx;
    if (expectedX == null) {
      expectedX = x;
    } else if ((x - expectedX).abs() > 5) {
      return false;
    }
  }
  return true;
}
