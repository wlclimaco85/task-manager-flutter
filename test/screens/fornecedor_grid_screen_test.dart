import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_windows_screen.dart';
import 'package:task_manager_flutter/mobile/screens/details/parceiro_detail_screen.dart';
import 'package:task_manager_flutter/mobile/screens/fornecedor_grid_screen.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/web/screens/details/parceiro_detail_screen.dart';
import 'package:task_manager_flutter/web/screens/fornecedor_grid_screen.dart';
import 'package:task_manager_flutter/windows/screens/details/parceiro_detail_screen.dart';
import 'package:task_manager_flutter/windows/screens/fornecedor_grid_screen.dart';

void main() {
  final hasPermission = (String _) => true;

  testWidgets('web usa endpoint de fornecedores e oferece detalhe do parceiro',
      (tester) async {
    final widget = await _buildResult(
      tester,
      (context) =>
          WebFornecedorGridScreen(hasPermission: hasPermission).build(context),
    );

    final grid = widget as DynamicGridWindowsScreen<Map<String, dynamic>>;
    expect(grid.fetchEndpointOverride, ApiLinks.allFornecedores);
    expect(grid.detailScreenBuilder, isNotNull);
    expect(
        grid.detailScreenBuilder!({'id': 1}), isA<WebParceiroDetailScreen>());
  });

  testWidgets(
      'windows usa endpoint de fornecedores e oferece detalhe do parceiro',
      (tester) async {
    final widget = await _buildResult(
      tester,
      (context) => WindowsFornecedorGridScreen(hasPermission: hasPermission)
          .build(context),
    );

    final grid = widget as DynamicGridWindowsScreen<Map<String, dynamic>>;
    expect(grid.fetchEndpointOverride, ApiLinks.allFornecedores);
    expect(grid.detailScreenBuilder, isNotNull);
    expect(
      grid.detailScreenBuilder!({'id': 1}),
      isA<WindowsParceiroDetailScreen>(),
    );
  });

  testWidgets('mobile usa o mesmo contrato restrito e oferece detalhe',
      (tester) async {
    final widget = await _buildResult(
      tester,
      (context) => MobileFornecedorGridScreen(hasPermission: hasPermission)
          .build(context),
    );

    final grid = widget as DynamicGridDynamicScreen;
    expect(grid.telaNome, 'parceiro');
    expect(grid.fetchEndpointOverride, ApiLinks.allFornecedores);
    expect(grid.createEndpointOverride, ApiLinks.createFornecedor);
    expect(grid.updateEndpointOverride, ApiLinks.updateFornecedor(':id'));
    expect(grid.deleteEndpointOverride, ApiLinks.deleteFornecedor(':id'));
    expect(grid.detailScreenBuilder, isNotNull);
    expect(
      grid.detailScreenBuilder!({'id': 1}),
      isA<MobileWebParceiroDetailScreen>(),
    );
  });
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
