import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/parceiro_form_rules.dart';
import '../../../widgets/parceiro_faturamento_dialog.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show BulkAction, CustomAction;
import 'details/parceiro_detail_screen.dart';

class WebParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.receipt_long,
          label: 'Faturar',
          onPressed: (context, item) => showParceiroFaturamentoDialog(
            context,
            parceiroIds: [_id(item)],
            todos: false,
          ),
        ),
      ],
      bulkActions: [
        BulkAction<Map<String, dynamic>>(
          icon: Icons.receipt_long,
          label: 'Faturar selecionados',
          onPressed: (context, items) => showParceiroFaturamentoDialog(
            context,
            parceiroIds: items.map(_id).toList(),
            todos: false,
          ),
        ),
      ],
      headerActions: [
        OutlinedButton.icon(
          onPressed: () => showParceiroFaturamentoDialog(
            context,
            parceiroIds: const [],
            todos: true,
          ),
          icon: const Icon(Icons.receipt_long, size: 18),
          label: const Text('Faturar todos'),
        ),
      ],
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
        DropdownHelpers.parceiroFieldScopedOrSelectable(),
        ...ParceiroFormRules.desktopModuleSuppression(),
      ],
      detailScreenBuilder: (item) =>
          WebParceiroDetailScreen(item: item, hasPermission: hasPermission),
    );
  }

  static int _id(Map<String, dynamic> item) => int.parse(item['id'].toString());
}
