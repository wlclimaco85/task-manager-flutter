import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_bancaria_model.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../widgets/finance/extrato_operacional_dialog.dart';

class WindowsContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsContaBancariaGridScreen({super.key, required this.hasPermission});

  static String _contaLabel(ContaBancaria conta) {
    final partes = [conta.banco, conta.agencia, conta.numero, conta.descricao]
        .where((item) => item != null && item.trim().isNotEmpty)
        .map((item) => item!.trim())
        .toList();
    return partes.isEmpty ? 'Conta bancária' : partes.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaBancaria>(
      telaNome: 'conta_bancaria',
      hasPermission: hasPermission,
      fromJson: (json) => ContaBancaria.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
        DropdownHelpers.parceiroFieldScopedOrSelectable(),
      ],
      customActions: () => [
        CustomAction<ContaBancaria>(
          icon: Icons.table_view,
          label: 'Extrato Operacional',
          isVisible: (item) => item.id != null,
          onPressed: (context, item) => ExtratoOperacionalDialog.show(
            context,
            contaId: item.id!,
            contaNome: _contaLabel(item),
          ),
        ),
      ],
    );
  }
}
