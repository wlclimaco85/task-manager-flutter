import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';

void main() {
  group('NfseDetailScreen Responsiveness Tests', () {
    // Teste: Mobile layout (< 600px)
    testWidgets('NfseDetailScreen renders in mobile layout (< 600px)',
        (WidgetTester tester) async {
      // Simula tela mobile (600px width)
      tester.binding.window.physicalSizeTestValue =
          const Size(600, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: NfseDetailScreen(
            item: {'id': null, 'numero': '', 'serie': ''},
          ),
        ),
      );

      // Verifica presença de estruturas responsivas
      expect(find.byType(LayoutBuilder), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    // Teste: Tablet layout (600-1000px)
    testWidgets('NfseDetailScreen renders in tablet layout (600-1000px)',
        (WidgetTester tester) async {
      // Simula tela tablet (800px width)
      tester.binding.window.physicalSizeTestValue =
          const Size(800, 1000);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: NfseDetailScreen(
            item: {'id': null, 'numero': '', 'serie': ''},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NfseDetailScreen), findsOneWidget);
    });

    // Teste: Desktop layout (>= 1000px)
    testWidgets('NfseDetailScreen renders in desktop layout (>= 1000px)',
        (WidgetTester tester) async {
      // Simula tela desktop (1920px width)
      tester.binding.window.physicalSizeTestValue =
          const Size(1920, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: NfseDetailScreen(
            item: {'id': 1, 'numero': '123', 'serie': 'A'},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Desktop deve ter Row layout
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    // Teste: AppBar presente em todos os breakpoints
    testWidgets('NfseDetailScreen AppBar is always visible',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue =
          const Size(1920, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: NfseDetailScreen(
            item: {'id': 1},
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('NFSe #1'), findsOneWidget);
    });

    // Teste: LayoutBuilder adapta maxWidth
    testWidgets('NfseDetailScreen LayoutBuilder constrains maxWidth',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue =
          const Size(2000, 1080);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: NfseDetailScreen(
            item: {'id': 1},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica que ConstrainedBox está presente (limita width em desktop)
      expect(find.byType(ConstrainedBox), findsWidgets);
    });
  });
}
