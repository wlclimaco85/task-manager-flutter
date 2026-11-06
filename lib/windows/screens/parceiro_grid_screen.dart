import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../services/nfse_logo_service.dart';
import '../../../utils/api_links.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/parceiro_form_rules.dart';
import '../../../widgets/nfse_logo_dialog.dart';
import '../../../widgets/parceiro_faturamento_dialog.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show BulkAction, CustomAction;
import '../../windows/screens/details/parceiro_detail_screen.dart';

class WindowsParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsParceiroGridScreen({super.key, required this.hasPermission});

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
        CustomAction<Map<String, dynamic>>(
          icon: Icons.image_outlined,
          label: 'Logo NFS-e',
          onPressed: (context, item) => showDialog<void>(
            context: context,
            builder: (_) => NfseLogoDialog(
              titulo: (item['nome'] ?? item['razaoSocial'] ?? '').toString(),
              urlLogo: ApiLinks.nfseLogoParceiro(_id(item).toString()),
              enviar: (bytes, nome) => NfseLogoService.enviarParceiro(_id(item), bytes, nome),
            ),
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
          WindowsParceiroDetailScreen(item: item, hasPermission: hasPermission),
    );
  }

  static int _id(Map<String, dynamic> item) => int.parse(item['id'].toString());
}
