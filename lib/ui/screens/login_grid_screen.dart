import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';

class LoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const LoginGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Login>(
      title: "Logins",
      fetchEndpoint: ApiLinks.allLogins,
      createEndpoint: ApiLinks.createLogin,
      updateEndpoint: ApiLinks.updateLogin(":id"),
      deleteEndpoint: ApiLinks.deleteLogin(":id"),
      fromJson: (json) => Login.fromJson(json),
      toJson: (login) => login.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Login.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dhCreatedAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'logins',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50, 100],
      ),
      onItemTap: (login, context) {
        // Navigate to detail screen if needed
        // Navigator.push(context, MaterialPageRoute(builder: (_) => LoginDetailScreen(login)));
      },
      customActions: (context) => [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Open settings
          },
        ),
      ],
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
