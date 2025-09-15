import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/plano_model.dart';

class PlanoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const PlanoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Plano>(
      title: "Planos",
      fetchEndpoint: ApiLinks.allPlanos,
      createEndpoint: ApiLinks.createPlano,
      updateEndpoint: ApiLinks.updatePlano(":id"),
      deleteEndpoint: ApiLinks.deletePlano(":id"),
      fromJson: (json) => Plano.fromJson(json),
      toJson: (p) => p.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Plano.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'planos',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
