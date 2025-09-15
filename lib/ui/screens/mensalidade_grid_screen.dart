import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/mensalidade_model.dart';

class MensalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const MensalidadeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Mensalidade>(
      title: "Mensalidades",
      fetchEndpoint: ApiLinks.allMensalidades,
      createEndpoint: ApiLinks.createMensalidade,
      updateEndpoint: ApiLinks.updateMensalidade(":id"),
      deleteEndpoint: ApiLinks.deleteMensalidade(":id"),
      fromJson: (json) => Mensalidade.fromJson(json),
      toJson: (m) => m.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Mensalidade.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dtPagamento',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'mensalidades',
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
