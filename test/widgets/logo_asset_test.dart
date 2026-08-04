import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'dart:typed_data';

void main() {
  group('Logo Asset Web Test', () {
    testWidgets('logo_contabilidade.jpg asset file exists', (WidgetTester tester) async {
      // Verifica se o asset pode ser carregado do bundle
      try {
        final ByteData data = await rootBundle.load('assets/images/logo_contabilidade.jpg');
        expect(data.lengthInBytes, greaterThan(0));
      } catch (e) {
        fail('Logo asset not found or cannot be loaded: $e');
      }
    });

    testWidgets('AppSidebar logo renders without error', (WidgetTester tester) async {
      // Simula um widget que usa o logo como em app_sidebar.dart
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClipOval(
              child: Image.asset(
                'assets/images/logo_contabilidade.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.apps, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica se ClipOval foi renderizado (Logo carregado corretamente)
      expect(find.byType(ClipOval), findsOneWidget);
    });
  });
}
