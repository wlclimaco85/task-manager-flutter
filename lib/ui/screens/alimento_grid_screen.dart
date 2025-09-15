import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/alimento_model.dart';

class AlimentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const AlimentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Alimento>(
      title: "Alimentos",
      fetchEndpoint: ApiLinks.allAlimentos,
      createEndpoint: ApiLinks.createAlimento,
      updateEndpoint: ApiLinks.updateAlimento(":id"),
      deleteEndpoint: ApiLinks.deleteAlimento(":id"),
      fromJson: (json) => Alimento.fromJson(json),
      toJson: (alimento) => alimento.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Alimento.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'alimentos',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50, 100],
      ),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
