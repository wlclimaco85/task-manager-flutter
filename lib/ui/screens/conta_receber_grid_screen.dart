// conta_receber_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/ui/screens/baixa_dialog_receber.dart';

class ContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<ContaReceber>(
      title: "Contas a Receber",
      fetchEndpoint: ApiLinks.allContasReceber,
      createEndpoint: ApiLinks.createContaReceber,
      updateEndpoint: ApiLinks.updateContaReceber(":id"),
      deleteEndpoint: ApiLinks.deleteContaReceber(":id"),
      fromJson: (json) => ContaReceber.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: ContaReceber.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      customActions: () => [
        CustomAction<ContaReceber>(
          icon: Icons.payment,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (object) => object.status == StatusContaReceber.ABERTA,
        ),
      ],
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'contas_receber',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialogReceber(conta: conta);
      },
    );
  }
}
