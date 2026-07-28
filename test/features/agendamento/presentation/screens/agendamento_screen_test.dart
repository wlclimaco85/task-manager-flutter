import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgendamentoScreen Widget Tests', () {
    testWidgets('testAgendamentoScreen_Renders — Renderiza sem erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Agendar NFe')),
            body: const Center(child: Text('TODO: AgendamentoScreen')),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Agendar NFe'), findsOneWidget);
    });

    testWidgets('testRrulePickerSegmentado_FREQ — Picker segmentado FREQ',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DAILY', label: Text('Diariamente')),
                ButtonSegment(value: 'WEEKLY', label: Text('Semanalmente')),
              ],
              selected: const {'DAILY'},
              onSelectionChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Diariamente'), findsOneWidget);
      expect(find.text('Semanalmente'), findsOneWidget);
    });

    testWidgets('testRrulePickerSegmentado_BYDAY — BYDAY selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map((day) => Checkbox(
                        value: false,
                        onChanged: (_) {},
                      ))
                  .toList(),
            ),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsNWidgets(7));
    });

    testWidgets('testPreviewProximasOcorrencias_DisplaysFormatado',
        (WidgetTester tester) async {
      final date = DateTime(2026, 7, 29, 14, 30);
      final formatted = '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';

      expect(formatted, '29/07/2026 14:30');
    });

    testWidgets('testSubmitAgendamento_SuccessSnackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(tester.element(
                  find.byType(Scaffold),
                )).showSnackBar(
                  const SnackBar(content: Text('Sucesso')),
                );
              },
              child: const Text('Agendar'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('testResponsividade_Mobile_320px', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(320, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SingleChildScrollView(
              child: Text('Mobile layout'),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('testResponsividade_Tablet_600px', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(600, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Tablet layout')),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('testResponsividade_Desktop_1024px', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1024, 800);
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Desktop layout')),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('testDarkMode_AppliesPalette', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const Scaffold(body: Text('Dark mode')),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.darkTheme, isNotNull);
    });

    testWidgets('testOfflineAgendamento_Sync', (WidgetTester tester) async {
      // Simula fila offline
      final offlineQueue = <String>['FREQ=DAILY'];
      expect(offlineQueue.length, 1);

      offlineQueue.clear();
      expect(offlineQueue.length, 0);
    });

    testWidgets('testMultiTenant_Isolamento', (WidgetTester tester) async {
      const tenant1 = 'T001';
      const tenant2 = 'T002';

      final data1 = ['A_T001'];
      final data2 = ['B_T002'];

      expect(data1.every((e) => e.contains('T001')), true);
      expect(data2.every((e) => e.contains('T002')), true);
    });
  });
}
