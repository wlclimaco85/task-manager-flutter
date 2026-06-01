import 'package:flutter/material.dart';
import 'package:task_manager_flutter/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import '../../../utils/security_matrix.dart';
import 'chamado_grid_screen.dart';

class ChamadosScreenDinamic extends StatelessWidget {
  const ChamadosScreenDinamic({super.key});

  bool _hasPermission(String permission) {
    final sec = SecurityMatrix.current();
    final lower = permission.toLowerCase();
    if (lower.contains('create') || lower.contains('insert')) {
      return sec.canInsert(AppScreen.chamados);
    }
    if (lower.contains('edit') || lower.contains('update')) {
      return sec.canUpdate(AppScreen.chamados);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return sec.canDelete(AppScreen.chamados);
    }
    return sec.canView(AppScreen.chamados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<Chamado>(
        title: 'Solicitações / Chamados',
        fetchEndpoint: ApiLinks.allChamados,
        createEndpoint: ApiLinks.createChamado,
        updateEndpoint: ApiLinks.updateChamado(':id'),
        deleteEndpoint: ApiLinks.deleteChamado(':id'),
        fieldConfigs: Chamado.fieldConfigsMobile(),
        idFieldName: 'id',
        useUserBannerAppBar: true,
        enableSearch: true,
        storageKey: 'chamados_mobile_grid',
        hasPermission: _hasPermission,
        fromJson: (json) => Chamado.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 20,
          availableRowsPerPage: [10, 20, 50],
        ),
      ),
    );
  }
}
