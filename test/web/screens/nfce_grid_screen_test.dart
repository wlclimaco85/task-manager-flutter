import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/nfce_grid_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/models/nfce_model.dart';

void main() {
  testWidgets('WebNfceGridScreen renders DynamicGridWindowsScreen with correct actions', (WidgetTester tester) async {
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

    // Valida que customActions nao e null e tem 4 acoes
    expect(dynamicGrid.customActions, isNotNull);

    final actions = dynamicGrid.customActions!();
    expect(actions.length, equals(4));

    expect(actions[0].label, equals('Cancelar'));
    expect(actions[1].label, contains('Conting'));
    expect(actions[2].label, equals('Gerar PDF'));
    expect(actions[3].label, equals('Enviar Email'));
  });
}
