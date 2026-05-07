import 'package:flutter/material.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/role_model.dart';
import '../../windows/screens/role_dialog.dart';

class WebRoleGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebRoleGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final int? loginId = ModalRoute.of(context)?.settings.arguments as int?;
    return DynamicGridWindowsScreen<Role>(
      telaNome: 'role',
      hasPermission: hasPermission,
      fromJson: (json) => Role.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.aplicativoField(),
      ],
      customActions: () => [
        CustomAction<Role>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) =>
              _showBaixaDialog(context, object, loginId),
          isVisible: (chamado) => true,
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, Role conta, int? loginId) {
    if (loginId == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RoleDialog(loginId: loginId);
      },
    );
  }
}


