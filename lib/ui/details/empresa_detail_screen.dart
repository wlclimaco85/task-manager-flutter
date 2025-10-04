import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/genericDetailFormScreen.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/empresa_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart'; // Add your Chamado model
import 'package:task_manager_flutter/data/models/chat_model.dart'; // Add your Chat model
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';

class EmpresaDetailScreen extends StatelessWidget {
  final Empresa item;
  final SecurityCheck hasPermission;

  const EmpresaDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  static List<TabConfig> getTabConfigs(Empresa item) => [
    // Main Data Tab (non-grid)
    TabConfig(
      title: "Dados Principais",
      icon: Icons.business,
      isGrid: false,
      endpoint: ApiLinks.allEmpresas,
      fields: Empresa.fieldConfigs.where((field) => field.isInForm).toList(),
    ),
    // Clientes Grid Tab
    TabConfig(
      title: "Clientes",
      icon: Icons.people,
      isGrid: true,
      endpoint: ApiLinks.clienteByEmpresaId(
        item.id.toString(),
      ), // Configure this in ApiLinks
      gridFieldConfigs:
          Parceiro.fieldConfigs, // Use your Cliente model field configs
    ),
    // Chamados Grid Tab
    TabConfig(
      title: "Chamados",
      icon: Icons.support_agent,
      isGrid: true,
      endpoint: ApiLinks.chamadoByEmpresaId(
        item.id.toString(),
      ), // Configure this in ApiLinks
      gridFieldConfigs:
          Chamado.fieldConfigs, // Use your Chamado model field configs
    ),
    // Chat Grid Tab
    TabConfig(
      title: "Chat",
      icon: Icons.chat,
      isGrid: true,
      endpoint: ApiLinks.chamadoByEmpresaId(
        item.id.toString(),
      ), // Configure this in ApiLinks
      gridFieldConfigs: ChatMessageModel
          .messageFieldConfigs, // Use your Chat model field configs
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen<Empresa>(
      item: item,
      tabConfigs: getTabConfigs(item),
      title: "Detalhes da Empresa",
      onSave: (formData) async {
        print("Salvar empresa: $formData");
        // Implement save logic here
        try {
          // Example implementation:
          // final response = await NetworkCaller().postRequest(
          //   ApiLinks.updateEmpresa(item.id.toString()),
          //   data: formData,
          // );
          // if (response.isSuccess) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(content: Text('Empresa salva com sucesso!')),
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
