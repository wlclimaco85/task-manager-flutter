import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/ui/details/regime_tributario_detail.dart';

class RegimeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const RegimeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<RegimeTributario>(
      title: "Regime Tributarios",
      fetchEndpoint: ApiLinks.allRegimetributario,
      createEndpoint: ApiLinks.createRegimetributario,
      updateEndpoint: ApiLinks.updateRegimetributario(":id"),
      deleteEndpoint: ApiLinks.deleteRegimetributario(":id"),
      fromJson: (json) => RegimeTributario.fromJson(json),
      toJson: (p) => p.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: RegimeTributario.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'Regime Tributarios',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
      detailScreenBuilder: (item) =>
          RegimeDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
