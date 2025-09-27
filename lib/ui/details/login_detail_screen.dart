import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/genericDetailFormScreen.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';
import 'package:task_manager_flutter/data/models/role_model.dart';

class LoginDetailScreen extends StatelessWidget {
  final Login item;
  final SecurityCheck hasPermission;

  const LoginDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  static List<TabConfig> get tabConfigs => [
    TabConfig(
      title: "Dados Principais",
      icon: Icons.person,
      isGrid: false,
      endpoint: ApiLinks.allParceiros,
      fields: Parceiro.fieldConfigs.where((field) => field.isInForm).toList(),
    ),
    TabConfig(
      title: "Roles",
      icon: Icons.history,
      isGrid: true,
      endpoint: ApiLinks.allRoles,
      gridFieldConfigs: Role.fieldConfigs,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen<Login>(
      item: item,
      tabConfigs: tabConfigs,
      title: "Detalhes do Parceiro",
      onSave: (formData) async {
        print("Salvar parceiro: $formData");
        // Implementar lógica de save aqui
        try {
          // Exemplo de implementação:
          // final response = await NetworkCaller().postRequest(
          //   ApiLinks.updateParceiro(item.id.toString()),
          //   data: formData,
          // );
          // if (response.isSuccess) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Parceiro salvo com sucesso!')),
          //   );
          // }
        } catch (e) {
          print("Erro ao salvar: $e");
        }
      },
      onBack: () => Navigator.pop(context),
      hasPermission: hasPermission,
    );
  }
}
