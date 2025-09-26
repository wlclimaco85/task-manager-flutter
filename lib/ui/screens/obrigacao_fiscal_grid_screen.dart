// conta_pagar_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/obrigacao_fiscal_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class ObrigacaoFiscalGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ObrigacaoFiscalGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<ObrigacaoFiscal>(
      title: "Obrigacões fiscais",
      fetchEndpoint: ApiLinks.allObrigacaoFiscal,
      createEndpoint: ApiLinks.createObrigacaoFiscal,
      updateEndpoint: ApiLinks.updateObrigacaoFiscal(":id"),
      deleteEndpoint: ApiLinks.deleteObrigacaoFiscal(":id"),
      fromJson: (json) => ObrigacaoFiscal.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ObrigacaoFiscal.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'audit.createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'Obrigacoes_fiscais',
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
