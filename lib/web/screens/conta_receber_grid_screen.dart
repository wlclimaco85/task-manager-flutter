import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
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
