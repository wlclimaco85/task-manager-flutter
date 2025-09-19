import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/diretorio_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class DiretorioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const DiretorioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Diretorio>(
      title: "Diretórios",
      fetchEndpoint: ApiLinks.allDiretorios,
      createEndpoint: ApiLinks.createDiretorio,
      updateEndpoint: ApiLinks.updateDiretorio(":id"),
      deleteEndpoint: ApiLinks.deleteDiretorio(":id"),
      fromJson: (json) => Diretorio.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Diretorio.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'diretorios',
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
