// conta_receber_grid_screen.dart
import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction, FieldConfigWindows;
import '../../../windows/screens/baixa_dialog_receber.dart';

class WindowsContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaReceber>(
      telaNome: 'conta_receber',
      hasPermission: hasPermission,
      fromJson: (json) => ContaReceber.fromJson(json),
      toJson: (a) => a.toJson(),
      fetchEndpointOverride: ApiLinks.allContasReceber,
      createEndpointOverride: ApiLinks.createContaReceber,
      updateEndpointOverride: ApiLinks.updateContaReceber(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaReceber(':id'),
      // H12: ocultar coluna parceiro da grid CR
      fieldOverrides: const [
        FieldConfigWindows(fieldName: 'parceiro',    label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'parceiroDev', label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'parceiroRec', label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
      ],
      customActions: () => [
        CustomAction<ContaReceber>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialogReceber(conta: conta);
      },
    );
  }
}
