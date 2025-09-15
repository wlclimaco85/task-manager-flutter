import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/objetivo_model.dart';

class ObjetivoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ObjetivoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Objetivo>(
      title: "Objetivos",
      fetchEndpoint: ApiLinks.allObjetivos,
      createEndpoint: ApiLinks.createObjetivo,
      updateEndpoint: ApiLinks.updateObjetivo(":id"),
      deleteEndpoint: ApiLinks.deleteObjetivo(":id"),
      fromJson: (json) => Objetivo.fromJson(json),
      toJson: (o) => o.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Objetivo.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'objetivos',
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
