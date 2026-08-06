import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';

void main() {
  group('ResponsiveHelper — Breakpoint System', () {
    test('Detecta mobile quando width < 768px', () {
      // Simular width = 320px (mobile)
      expect(ResponsiveHelper.getBreakpoint(320), equals(Breakpoint.mobile));
      expect(ResponsiveHelper.isMobile(320), isTrue);
      expect(ResponsiveHelper.isTablet(320), isFalse);
      expect(ResponsiveHelper.isDesktop(320), isFalse);
    });

    test('Detecta tablet quando 768 <= width < 1024px', () {
      // Simular width = 800px (tablet)
      expect(ResponsiveHelper.getBreakpoint(800), equals(Breakpoint.tablet));
      expect(ResponsiveHelper.isMobile(800), isFalse);
      expect(ResponsiveHelper.isTablet(800), isTrue);
      expect(ResponsiveHelper.isDesktop(800), isFalse);
    });

    test('Detecta desktop quando width >= 1024px', () {
      // Simular width = 1200px (desktop)
      expect(ResponsiveHelper.getBreakpoint(1200), equals(Breakpoint.desktop));
      expect(ResponsiveHelper.isMobile(1200), isFalse);
      expect(ResponsiveHelper.isTablet(1200), isFalse);
      expect(ResponsiveHelper.isDesktop(1200), isTrue);
    });

    test('Retorna valores de padding para cada breakpoint', () {
      // Mobile: padding menor
      expect(ResponsiveHelper.paddingForBreakpoint(320), equals(8.0));

      // Tablet: padding médio
      expect(ResponsiveHelper.paddingForBreakpoint(800), equals(16.0));

      // Desktop: padding maior
      expect(ResponsiveHelper.paddingForBreakpoint(1200), equals(24.0));
    });

    test('Retorna tamanho de fonte escalado para cada breakpoint', () {
      // Mobile: fonte menor
      expect(ResponsiveHelper.fontSizeForBreakpoint(320, 16), equals(14.0));

      // Tablet: fonte normal
      expect(ResponsiveHelper.fontSizeForBreakpoint(800, 16), equals(16.0));

      // Desktop: fonte maior
      expect(ResponsiveHelper.fontSizeForBreakpoint(1200, 16), equals(18.0));
    });

    test('Detecta corretamente breakpoint de 768px (limite tablet)', () {
      // Exatamente 768 é tablet
      expect(ResponsiveHelper.getBreakpoint(768), equals(Breakpoint.tablet));
      expect(ResponsiveHelper.isTablet(768), isTrue);
    });

    test('Detecta corretamente breakpoint de 1024px (limite desktop)', () {
      // Exatamente 1024 é desktop
      expect(ResponsiveHelper.getBreakpoint(1024), equals(Breakpoint.desktop));
      expect(ResponsiveHelper.isDesktop(1024), isTrue);
    });

    test('Retorna breakpoint padrão quando width inválido', () {
      // Width zero ou negativo retorna mobile
      expect(ResponsiveHelper.getBreakpoint(0), equals(Breakpoint.mobile));
      expect(ResponsiveHelper.getBreakpoint(-100), equals(Breakpoint.mobile));
    });

    test('Padding e font size são números válidos (não nulos)', () {
      final padding = ResponsiveHelper.paddingForBreakpoint(500);
      final fontSize = ResponsiveHelper.fontSizeForBreakpoint(500, 14);

      expect(padding, isNotNull);
      expect(fontSize, isNotNull);
      expect(padding, greaterThan(0));
      expect(fontSize, greaterThan(0));
    });
  });
}
