// conta_pagar_grid_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction, FieldConfigWindows;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../utils/api_links.dart';
import '../../../windows/screens/baixa_dialog.dart';

class WindowsContaPagarGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaPagar>(
      telaNome: 'conta_pagar',
      hasPermission: hasPermission,
      fromJson: (json) => ContaPagar.fromJson(json),
      toJson: (a) => a.toJson(),
      fetchEndpointOverride: ApiLinks.allContasPagar,
      createEndpointOverride: ApiLinks.createContaPagar,
      updateEndpointOverride: ApiLinks.updateContaPagar(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaPagar(':id'),
      // H12: ocultar coluna parceiro da grid CP
      fieldOverrides: const [
        FieldConfigWindows(fieldName: 'parceiro',    label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'parceiroDev', label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'parceiroRec', label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
      ],
      customActions: () => [
        CustomAction<ContaPagar>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, ContaPagar conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialog(conta: conta);
      },
    );
  }
}
