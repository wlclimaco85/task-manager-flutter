import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/aplicativo_model.dart';

class AplicativoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const AplicativoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Aplicativo>(
      title: "Aplicativos",
      fetchEndpoint: ApiLinks.allAplicativos,
      createEndpoint: ApiLinks.createAplicativo,
      updateEndpoint: ApiLinks.updateAplicativo(":id"),
      deleteEndpoint: ApiLinks.deleteAplicativo(":id"),
      fromJson: (json) => Aplicativo.fromJson(json),
      toJson: (r) => r.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Aplicativo.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'roles',
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
