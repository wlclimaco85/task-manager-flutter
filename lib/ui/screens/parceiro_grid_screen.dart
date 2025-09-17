import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/details/parceiro_detail_screen.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class ParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Parceiro>(
      title: "Parceiros",
      fetchEndpoint: ApiLinks.allParceiros,
      createEndpoint: ApiLinks.createParceiro,
      updateEndpoint: ApiLinks.updateParceiro(":id"),
      deleteEndpoint: ApiLinks.deleteParceiro(":id"),
      fromJson: (json) => Parceiro.fromJson(json),
      toJson: (p) => p.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Parceiro.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'parceiros',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
      detailScreenBuilder: (item) => ParceiroDetailScreen(
        item: item, // Agora está correto - passando o item
        hasPermission: hasPermission,
      ),
    );
  }
}
