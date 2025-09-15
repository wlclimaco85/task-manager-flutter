import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/exame_model.dart';

class ExameGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ExameGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Exame>(
      title: "Exames",
      fetchEndpoint: ApiLinks.allExames,
      createEndpoint: ApiLinks.createExame,
      updateEndpoint: ApiLinks.updateExame(":id"),
      deleteEndpoint: ApiLinks.deleteExame(":id"),
      fromJson: (json) => Exame.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Exame.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dtExame',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'exames',
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
