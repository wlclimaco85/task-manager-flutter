import 'package:flutter/material.dart';
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class WebLoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const WebLoginDetailScreen({super.key, required this.item, required this.hasPermission});

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
          // "Excluir" nesta aba DESVINCULA a role do login (não apaga a role).
          // Backend: DELETE /api/logins/{loginId}/roles/{roleId} (removerRole).
          deleteEndpointOverride:
              '${ApiLinks.baseUrl}/api/logins/$loginId/roles/:id',
        ),
        RelatedGridTab(
          title: 'Setores',
          icon: Icons.business_center,
          telaNome: 'setor',
          extraParams: {'loginId': loginId},
          // "Excluir" nesta aba DESVINCULA o setor do login (não apaga o setor).
          // Backend: DELETE /api/login/{loginId}/setores/{setorId}
          deleteEndpointOverride:
              '${ApiLinks.baseUrl}/api/login/$loginId/setores/:id',
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
