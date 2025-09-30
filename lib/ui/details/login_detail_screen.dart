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

  // 🔹 Agora é um getter normal (não static)
  List<TabConfig> get tabConfigs => [
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
      endpoint: ApiLinks.getRolesLoginId(item.id?.toString() ?? ''),
      gridFieldConfigs: Role.fieldConfigs,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen<Login>(
      item: item,
      tabConfigs: tabConfigs, // ✅ funciona agora
      title: "Detalhes do Parceiro",
      onSave: (formData) async {
        print("Salvar parceiro: $formData");
        try {
          // implementar lógica de save aqui
        } catch (e) {
          print("Erro ao salvar: $e");
        }
      },
      onBack: () => Navigator.pop(context),
      hasPermission: hasPermission,
    );
  }
}
