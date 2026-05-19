import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/role_model.dart';
import '../../windows/screens/role_dialog.dart';

class WindowsRoleGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsRoleGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    int loginId = ModalRoute.of(context)!.settings.arguments as int;
    return DynamicGridWindowsScreen<Role>(
      telaNome: 'Roles', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => Role.fromJson(json),
      toJson: (a) => a.toJson(),

      // 🔥 AQUI entram os botões extras por linha
      customActions: () => [
        CustomAction<Role>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) =>
              _showBaixaDialog(context, object, loginId),

          // opcional: só mostra se ainda não estiver fechado
          // ajusta de acordo com o seu modelo
          isVisible: (chamado) {
            // exemplo genérico, muda conforme seu ChamadoModel:
            // return chamado.status != 'FECHADO';
            return true;
          },
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, Role conta, int loginId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RoleDialog(loginId: loginId);
      },
    );
  }
}
