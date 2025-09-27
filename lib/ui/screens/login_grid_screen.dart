import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';
import 'package:task_manager_flutter/ui/details/login_detail_screen.dart';

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
      detailScreenBuilder: (item) => LoginDetailScreen(
        item: item, // Agora está correto - passando o item
        hasPermission: hasPermission,
      ),
      customActions: () => [
        CustomAction<Login>(
          icon: Icons.payment,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
        ),
      ],
      enableSearch: true,
      enableColumnReorder: true,
    );
  }

  void _showBaixaDialog(BuildContext context, Login conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bom Dia!'),
          content: const Text('Tenha um excelente dia! 😊'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
