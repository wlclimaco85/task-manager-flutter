import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/dieta_model.dart';

class DietaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const DietaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Dieta>(
      title: "Dietas",
      fetchEndpoint: ApiLinks.allDietas,
      createEndpoint: ApiLinks.createDieta,
      updateEndpoint: ApiLinks.updateDieta(":id"),
      deleteEndpoint: ApiLinks.deleteDieta(":id"),
      fromJson: (json) => Dieta.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Dieta.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dtConsulta',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'dietas',
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
