import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/customization/generic_grid/grid_form.dart';
import 'package:task_manager_flutter/mobile/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/utils/parceiro_form_rules.dart';
import 'package:task_manager_flutter/web/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/windows/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows;

void main() {
  final hasPermission = (String _) => true;

  testWidgets('cadastro de parceiro nao expoe Modulo Servicos', (tester) async {
    final web = await _buildResult(
      tester,
      (context) =>
          WebParceiroGridScreen(hasPermission: hasPermission).build(context),
    ) as DynamicGridWindowsScreen<Map<String, dynamic>>;
    final windows = await _buildResult(
      tester,
      (context) => WindowsParceiroGridScreen(hasPermission: hasPermission)
          .build(context),
    ) as DynamicGridWindowsScreen<Map<String, dynamic>>;
    final mobile = await _buildResult(
      tester,
      (context) =>
          ParceiroGridScreen(hasPermission: hasPermission).build(context),
    ) as DynamicGridDynamicScreen;

    _expectDesktopModulesHidden(web.fieldOverrides!);
    _expectDesktopModulesHidden(windows.fieldOverrides!);
    for (final alias in _moduleAliases) {
      expect(
        mobile.fieldOverrides!
            .singleWhere((field) => field.fieldName == alias)
            .isInForm,
        isFalse,
      );
    }
  });

  testWidgets('tipo Fornecedor bloqueado nao abre seletor no mobile',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GridFormDialog(
            titleNew: 'Novo Fornecedor',
            titleEdit: 'Editar Fornecedor',
            fieldConfigs: [ParceiroFormRules.mobileSupplierType()],
            createEndpoint: '/api/cadastros/fornecedores',
            updateEndpoint: '/api/cadastros/fornecedores/:id',
            editingItem: null,
            idFieldName: 'id',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fornecedor'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text('Fornecedor'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });
}

const _moduleAliases = [
  'modulo_servicos',
  'moduloServicos',
  'modulosServico',
];

void _expectDesktopModulesHidden(List<FieldConfigWindows> fields) {
  for (final alias in _moduleAliases) {
    expect(
      fields.singleWhere((field) => field.fieldName == alias).isInForm,
      isFalse,
    );
  }
}

Future<Widget> _buildResult(
  WidgetTester tester,
  Widget Function(BuildContext context) builder,
) async {
  late Widget result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          result = builder(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}
