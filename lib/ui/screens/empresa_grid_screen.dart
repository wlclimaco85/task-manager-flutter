import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/ui/details/empresa_detail_screen.dart';

class EmpresaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const EmpresaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Empresa>(
      title: "Empresas",
      fetchEndpoint: ApiLinks.allEmpresas,
      createEndpoint: ApiLinks.createEmpresa,
      updateEndpoint: ApiLinks.updateEmpresa(":id"),
      deleteEndpoint: ApiLinks.deleteEmpresa(":id"),
      fromJson: (json) => Empresa.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Empresa.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'empresas',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
      detailScreenBuilder: (item) =>
          EmpresaDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
