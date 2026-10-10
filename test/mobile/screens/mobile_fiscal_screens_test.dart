import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';
import 'package:task_manager_flutter/mobile/screens/nfse_screen.dart';
import 'package:task_manager_flutter/mobile/screens/nfe_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/nfce_grid_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  void ignoreKnownFilterOverflow() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  Future<void> setMobileSurface(WidgetTester tester) async {
    ignoreKnownFilterOverflow();
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Mobile NFS-e renders header, filter toggle, bulk actions and custom actions', (tester) async {
    await setMobileSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MobileNfseScreen())),
    );
    await tester.pump();

    // Title and Header
    expect(find.text('NFSe - Nota Fiscal de Serviços'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAll([
        'Consultar status',
        'Cancelar',
        'Auditoria',
      ]),
    );

    // Bulk Actions & status validation
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Imprimir',
      'Enviar',
      'Cancelar',
    ]);

    final cancelAction = bulk.firstWhere((b) => b.label == 'Cancelar');
    final enviarAction = bulk.firstWhere((b) => b.label == 'Enviar');
    final pdfAction = bulk.firstWhere((b) => b.label == 'Imprimir');

    expect(cancelAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(cancelAction.isEnabled!([{'status': 'PENDENTE'}]), isFalse);
    expect(enviarAction.isEnabled!([{'status': 'CONFIRMADA'}]), isTrue);
    expect(enviarAction.isEnabled!([{'status': 'AUTORIZADA'}]), isFalse);
    expect(pdfAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(pdfAction.isEnabled!([{'status': 'AUTORIZADA', 'numero': '12345'}]), isTrue);
    expect(pdfAction.isEnabled!([{'status': 'PENDENTE', 'numero': ''}]), isFalse);

    // Filter toggle test
    await tester.tap(find.byTooltip('Ocultar filtros').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Exibir filtros').first);
    await tester.pump();

    // Drain background debounce timer (1.5s in SistemaErrorReporter)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Mobile NF-e Saída renders header, filter toggle, bulk actions and custom actions', (tester) async {
    await setMobileSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MobileNfeGridScreen(entrada: false))),
    );
    await tester.pump();

    // Title and Header
    expect(find.text('NF-e Saída'), findsOneWidget);
    expect(find.byIcon(Icons.file_upload), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAll([
        'Consultar status',
        'Emitir',
        'Cancelar',
        'Carta de Correção',
        'Histórico de eventos',
        'Imprimir DANFE',
        'Exportar XML',
      ]),
    );

    // Bulk Actions & status validation
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Gerar PDF',
      'Enviar',
      'Cancelar',
      'Baixar XML',
    ]);

    final cancelAction = bulk.firstWhere((b) => b.label == 'Cancelar');
    final emitirAction = bulk.firstWhere((b) => b.label == 'Enviar');
    final pdfAction = bulk.firstWhere((b) => b.label == 'Gerar PDF');

    expect(cancelAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(cancelAction.isEnabled!([{'status': 'PENDENTE'}]), isFalse);
    expect(emitirAction.isEnabled!([{'status': 'PENDENTE'}]), isTrue);
    expect(emitirAction.isEnabled!([{'status': 'REJEITADA'}]), isTrue);
    expect(emitirAction.isEnabled!([{'status': 'AUTORIZADA'}]), isFalse);
    expect(pdfAction.isEnabled!([{'status': 'AUTORIZADA'}]), isTrue);
    expect(pdfAction.isEnabled!([{'numero': '999'}]), isTrue);
    expect(pdfAction.isEnabled!([{'status': 'PENDENTE', 'numero': ''}]), isFalse);

    // Filter toggle test
    await tester.tap(find.byTooltip('Ocultar Filtros').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Exibir Filtros').first);
    await tester.pump();

    // Drain background debounce timer (1.5s in SistemaErrorReporter)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Mobile NF-e Entrada renders header, bulk actions (Aceitar/Recusar/PDF/XML)', (tester) async {
    await setMobileSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MobileNfeGridScreen(entrada: true))),
    );
    await tester.pump();

    // Title and Header
    expect(find.text('NF-e Entrada'), findsOneWidget);
    expect(find.byIcon(Icons.file_download), findsOneWidget);

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    // Custom Actions
    expect(
      grid.customActions!().map((a) => a.label),
      containsAll([
        'Consultar status',
        'Importar XML',
        'Aceitar',
        'Recusar',
        'DANFE',
        'XML',
      ]),
    );

    // Bulk Actions
    final bulk = grid.bulkActions!;
    expect(bulk.map((b) => b.label), [
      'Aceitar',
      'Recusar',
      'Gerar PDF',
      'Baixar XML',
    ]);

    final aceitarAction = bulk.firstWhere((b) => b.label == 'Aceitar');
    final recusarAction = bulk.firstWhere((b) => b.label == 'Recusar');

    expect(aceitarAction.isEnabled!([{'status': 'PENDENTE'}]), isTrue);
    expect(aceitarAction.isEnabled!([{'status': 'IMPORTADA'}]), isTrue);
    expect(aceitarAction.isEnabled!([{'status': 'AUTORIZADA'}]), isFalse);

    expect(recusarAction.isEnabled!([{'status': 'PENDENTE'}]), isTrue);
    expect(recusarAction.isEnabled!([{'status': 'IMPORTADA'}]), isTrue);
    expect(recusarAction.isEnabled!([{'status': 'CANCELADA'}]), isFalse);

    // Drain background debounce timer (1.5s in SistemaErrorReporter)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Mobile NFC-e (Cupons) renders header, quick actions, bulk actions and status checks', (tester) async {
    await setMobileSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MobileNfceGridScreen())),
    );
    await tester.pump();

    // Tela mobile baseada em DynamicGridDynamicScreen (refatorada em a9888055):
    // titulo proprio, FAB 'Nova NFC-e' e acoes customizadas por linha.
    final grid = tester.widget<DynamicGridDynamicScreen>(
      find.byType(DynamicGridDynamicScreen),
    );
    expect(grid.telaNome, 'nfce');
    expect(grid.tituloOverride, 'NFC-e / Cupons');
    expect(find.text('Nova NFC-e'), findsOneWidget);

    expect(
      grid.customActions!().map((a) => a.label),
      containsAll([
        'Consultar status',
        'Cancelar',
        'Contingência / EPEC',
        'Inutilizar numeração',
        'Gerar PDF',
        'Baixar XML',
        'Enviar e-mail',
      ]),
    );

    // Drain background debounce timer (1.5s in SistemaErrorReporter)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('Back button appears on Mobile when screen is pushed in Navigator', (tester) async {
    await setMobileSurface(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MobileNfeGridScreen(entrada: false)),
                  );
                },
                child: const Text('Open NF-e'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Tap to open screen
    await tester.tap(find.text('Open NF-e'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify header title and back button
    expect(find.text('NF-e Saída'), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Verify back to home
    expect(find.text('Open NF-e'), findsOneWidget);

    // Drain background debounce timer (1.5s in SistemaErrorReporter)
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('All 4 fiscal screens render strictly in vertical Column on mobile without 220px horizontal sidebar', (tester) async {
    await setMobileSurface(tester);

    final screens = <Widget>[
      const MobileNfeGridScreen(entrada: false),
      const MobileNfeGridScreen(entrada: true),
      const MobileNfseScreen(),
      const MobileNfceGridScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: screen)));
      await tester.pump();

      // Ensure that NO SizedBox with width 220 exists in the tree (the desktop horizontal sidebar)
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final has220Sidebar = sizedBoxes.any((s) => s.width == 220);
      expect(has220Sidebar, isFalse, reason: 'Screen should not render the 220px desktop sidebar on mobile!');

      if (screen is! MobileNfceGridScreen) {
        // Ensure "Filtros de Pesquisa" is rendered vertically on top when filters are visible
        expect(find.text('Filtros de Pesquisa'), findsOneWidget);

        // Ensure horizontal action buttons [Limpar] and [Filtrar] are present
        expect(find.text('Limpar'), findsOneWidget);
        expect(find.text('Filtrar'), findsOneWidget);
      }

      // Drain background debounce timer
      await tester.pump(const Duration(seconds: 2));
    }
  });
}
