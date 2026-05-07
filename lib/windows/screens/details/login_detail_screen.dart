import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class WindowsLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const WindowsLoginDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final loginId = item.id?.toString() ?? '';
    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'login',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Roles',
          icon: Icons.security,
          telaNome: 'role',
          extraParams: {'loginId': loginId},
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'usuarioAberturaId': loginId},
        ),
      ],
    );
  }
}
