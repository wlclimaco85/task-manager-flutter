import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/nfce_grid_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';

void main() {
  testWidgets(
      'WebNfceGridScreen renders DynamicGridWindowsScreen with correct actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WebNfceGridScreen(
          hasPermission: (String permission) => true,
        ),
      ),
    ));

    await tester.pump();

    // Verifica que o DynamicGridWindowsScreen foi montado
    expect(find.byType(DynamicGridWindowsScreen<NfceModel>), findsOneWidget);

    // Extrai o widget e verifica propriedades
    final dynamicGrid = tester.widget<DynamicGridWindowsScreen<NfceModel>>(
      find.byType(DynamicGridWindowsScreen<NfceModel>),
    );

    expect(dynamicGrid.tituloOverride, equals('NFC-e / Cupons'));
    expect(dynamicGrid.telaNome, equals('nfce'));
    expect(dynamicGrid.fetchEndpointOverride, contains('/api/v1/nfce'));
    expect(dynamicGrid.createEndpointOverride, contains('/api/v1/nfce'));

    // Valida que customActions nao e null e tem as opcoes fiscais da linha.
    expect(dynamicGrid.customActions, isNotNull);

    final actions = dynamicGrid.customActions!();
    expect(
      actions.map((a) => a.label),
      containsAllInOrder([
        'Consultar status',
        'Cancelar',
        'Cancelar por substituição',
        'Contingência / EPEC',
        'Inutilizar numeração',
        'Gerar PDF',
        'Baixar XML',
        'Enviar e-mail',
      ]),
    );

    expect(actions.length, equals(8));

    // Drena eventuais timers de log/erro de rede assíncronos
    await tester.pump(const Duration(seconds: 2));
  });
}
