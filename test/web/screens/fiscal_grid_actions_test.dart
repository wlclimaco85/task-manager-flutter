import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/web/screens/nfe_grid_screen.dart';
import 'package:task_manager_flutter/web/screens/nfse_screen.dart';

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

  Future<void> setWideSurface(WidgetTester tester) async {
    ignoreKnownFilterOverflow();
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('NF-e saida exposes fiscal row actions', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfeGridScreen(entrada: false))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Emitir',
        'Cancelar',
        'Carta de Correção',
        'Histórico de eventos',
        'Imprimir DANFE',
        'Exportar XML',
      ]),
    );
  });

  testWidgets('NF-e entrada exposes fiscal row actions', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WebNfeGridScreen(entrada: true))),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Importar XML',
        'Aceitar',
        'Recusar',
        'DANFE',
        'XML',
      ]),
    );
  });

  testWidgets('NFS-e exposes fiscal row actions', (tester) async {
    await setWideSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NfseScreen())),
    );
    await tester.pump();

    final grid = tester.widget<DynamicGridWindowsScreen<Map<String, dynamic>>>(
      find.byType(DynamicGridWindowsScreen<Map<String, dynamic>>),
    );

    expect(
      grid.customActions!().map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Cancelar',
        'Auditoria',
      ]),
    );
  });
}
