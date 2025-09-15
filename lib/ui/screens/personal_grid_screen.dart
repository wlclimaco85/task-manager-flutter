import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/personal_model.dart';

class PersonalGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const PersonalGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Personal>(
      title: "Personais",
      fetchEndpoint: ApiLinks.allPersonais,
      createEndpoint: ApiLinks.createPersonal,
      updateEndpoint: ApiLinks.updatePersonal(":id"),
      deleteEndpoint: ApiLinks.deletePersonal(":id"),
      fromJson: (json) => Personal.fromJson(json),
      toJson: (p) => p.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Personal.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'personais',
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
