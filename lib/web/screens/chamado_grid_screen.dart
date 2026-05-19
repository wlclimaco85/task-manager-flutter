import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../web/screens/fechar_chamado_dialog.dart';

class WebChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final loginId = AuthUtility.userInfo?.login?.id?.toString() ?? AuthUtility.userInfo?.data?.id?.toString() ?? '';

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'chamado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      extraParams: loginId.isNotEmpty ? {'loginId': loginId} : null,
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.check_circle, label: 'Fechar',
          onPressed: (context, chamado) => showDialog(context: context, builder: (ctx) => WebFecharChamadoDialog(chamadoId: chamado['id'] ?? 0)),
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
