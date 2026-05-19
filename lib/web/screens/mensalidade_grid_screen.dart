import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/mensalidade_model.dart';

class WebMensalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebMensalidadeGridScreen({super.key, required this.hasPermission});

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
