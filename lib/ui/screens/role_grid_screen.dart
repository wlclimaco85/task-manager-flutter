import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/role_model.dart';

class RoleGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const RoleGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Role>(
      title: "Roles",
      fetchEndpoint: ApiLinks.allRoles,
      createEndpoint: ApiLinks.createRole,
      updateEndpoint: ApiLinks.updateRole(":id"),
      deleteEndpoint: ApiLinks.deleteRole(":id"),
      fromJson: (json) => Role.fromJson(json),
      toJson: (r) => r.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Role.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'roles',
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
