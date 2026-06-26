import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class WindowsLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const WindowsLoginDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final loginId = item.id?.toString() ?? '';
    final empresaId = item.empresa?.id?.toString() ?? '';
    final parceiroId = item.parceiro?.id?.toString() ?? '';
    return GenericDetailFormScreen(
      item: item.toJson(),
      telaNome: 'login',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Roles',
          icon: Icons.security,
          telaNome: 'role',
          extraParams: {'loginId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
          deleteEndpointOverride:
              '${ApiLinks.baseUrl}/api/logins/$loginId/roles/:id',
        ),
        RelatedGridTab(
          title: 'Setores',
          icon: Icons.business_center,
          telaNome: 'setor',
          extraParams: {'loginId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
          deleteEndpointOverride:
              '${ApiLinks.baseUrl}/api/login/$loginId/setores/:id',
        ),
        RelatedGridTab(
          title: 'Chamados',
          icon: Icons.support_agent,
          telaNome: 'chamado',
          extraParams: {'usuarioAberturaId': loginId, 'empresaId': empresaId, 'parceiroId': parceiroId},
        ),
      ],
    );
  }
}
