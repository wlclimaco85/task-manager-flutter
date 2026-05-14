import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction, FieldConfigWindows;
import '../../../windows/screens/baixa_dialog_receber.dart';

class WebContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'conta_receber',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fetchEndpointOverride: ApiLinks.allContasReceber,
      createEndpointOverride: ApiLinks.createContaReceber,
      updateEndpointOverride: ApiLinks.updateContaReceber(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaReceber(':id'),
      // H12: ocultar coluna parceiro da grid CR mas manter no form
      fieldOverrides: const [
        FieldConfigWindows(fieldName: 'parceiro',    label: 'Parceiro',     isInForm: true, isInGrid: false, isVisibleByDefault: false),
        FieldConfigWindows(fieldName: 'parceiroDev', label: 'Parceiro Dev', isInForm: true, isInGrid: false, isVisibleByDefault: false),
        FieldConfigWindows(fieldName: 'parceiroRec', label: 'Parceiro Rec', isInForm: true, isInGrid: false, isVisibleByDefault: false),
      ],
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle, label: 'Baixar',
          onPressed: (context, object) => showDialog(context: context, builder: (_) => BaixaDialogReceber(conta: ContaReceber.fromJson(object))),
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
