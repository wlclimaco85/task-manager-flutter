import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class FormaPagamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const FormaPagamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<FormaPagamento>(
      title: "Formas de Pagamento",
      fetchEndpoint: ApiLinks.allFormasPagamento,
      createEndpoint: ApiLinks.createFormaPagamento,
      updateEndpoint: ApiLinks.updateFormaPagamento(":id"),
      deleteEndpoint: ApiLinks.deleteFormaPagamento(":id"),
      fromJson: (json) => FormaPagamento.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: FormaPagamento.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'formas_pagamento',
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
