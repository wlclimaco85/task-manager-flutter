import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/setor_model.dart';

class SetorGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const SetorGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Setor>(
      title: "Setores",
      fetchEndpoint: ApiLinks.allSetores,
      createEndpoint: ApiLinks.createSetor,
      updateEndpoint: ApiLinks.updateSetor(":id"),
      deleteEndpoint: ApiLinks.deleteSetor(":id"),
      fromJson: (json) => Setor.fromJson(json),
      toJson: (s) => s.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Setor.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'setores',
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
