import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/modalidade_model.dart';

class ModalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ModalidadeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Modalidade>(
      title: "Modalidades",
      fetchEndpoint: ApiLinks.allModalidades,
      createEndpoint: ApiLinks.createModalidade,
      updateEndpoint: ApiLinks.updateModalidade(":id"),
      deleteEndpoint: ApiLinks.deleteModalidade(":id"),
      fromJson: (json) => Modalidade.fromJson(json),
      toJson: (m) => m.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Modalidade.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'modalidades',
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
