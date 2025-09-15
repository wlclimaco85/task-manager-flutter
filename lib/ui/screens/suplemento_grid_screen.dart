import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/suplemento_model.dart';

class SuplementoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const SuplementoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Suplemento>(
      title: "Suplementos",
      fetchEndpoint: ApiLinks.allSuplementos,
      createEndpoint: ApiLinks.createSuplemento,
      updateEndpoint: ApiLinks.updateSuplemento(":id"),
      deleteEndpoint: ApiLinks.deleteSuplemento(":id"),
      fromJson: (json) => Suplemento.fromJson(json),
      toJson: (s) => s.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Suplemento.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dtInicio',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'suplementos',
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
