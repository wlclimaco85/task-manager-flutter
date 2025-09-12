import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

import 'package:task_manager_flutter/data/models/comunicados_model.dart';

class ComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Comunicado>(
      title: "Comunicados",
      fetchEndpoint: ApiLinks.allComunicados,
      createEndpoint: ApiLinks.createComunicado,
      updateEndpoint: ApiLinks.updateComunicado(":id"),
      deleteEndpoint: ApiLinks.deleteComunicado(":id"),
      fromJson: (json) => Comunicado.fromJson(json),
      toJson: (comunicado) => comunicado.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Comunicado.fieldConfigs,
      idFieldName: '_id',
      dateFieldName: 'dhCreatedAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'comunicados',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50, 100],
      ),
      onItemTap: (comunicado, context) {
        // Navegar para tela de detalhes
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ComunicadoDetailScreen(comunicado)));
      },
      customActions: (context) => [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Abrir configurações
          },
        ),
      ],
      enableSearch: true,
      enableColumnReorder: true,
      initialFilters: {'categoria': 'Urgente'}, // Filtro inicial
    );
  }
}
