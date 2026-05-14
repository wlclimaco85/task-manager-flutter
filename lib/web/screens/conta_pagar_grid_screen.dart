import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction, FieldConfigWindows;
import '../../../windows/screens/baixa_dialog.dart';

class WebContaPagarGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'conta_pagar',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fetchEndpointOverride: ApiLinks.allContasPagar,
      createEndpointOverride: ApiLinks.createContaPagar,
      updateEndpointOverride: ApiLinks.updateContaPagar(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaPagar(':id'),
      // H12: ocultar coluna parceiro da grid CP mas manter no form
      fieldOverrides: const [
        FieldConfigWindows(fieldName: 'parceiro',    label: 'Parceiro',     isInForm: true, isInGrid: false, isVisibleByDefault: false),
        FieldConfigWindows(fieldName: 'parceiroDev', label: 'Parceiro Dev', isInForm: true, isInGrid: false, isVisibleByDefault: false),
        FieldConfigWindows(fieldName: 'parceiroRec', label: 'Parceiro Rec', isInForm: true, isInGrid: false, isVisibleByDefault: false),
      ],
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle, label: 'Baixar',
          onPressed: (context, object) => showDialog(context: context, builder: (_) => BaixaDialog(conta: ContaPagar.fromJson(object))),
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
