import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/genericDetailFormScreen.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/widgets/tab_config.dart';
import 'package:task_manager_flutter/data/models/login_2_model.dart';

class ParceiroDetailScreen extends StatelessWidget {
  final Parceiro item;
  final SecurityCheck hasPermission;

  const ParceiroDetailScreen({
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
      title: "Endereço",
      icon: Icons.location_on,
      isGrid: false,
      endpoint: ApiLinks.allParceiros,
      fields: [
        FieldConfig(
          label: "Rua",
          fieldName: "endereco.rua",
          icon: Icons.streetview,
          isInForm: true,
        ),
        FieldConfig(
          label: "Número",
          fieldName: "endereco.numero",
          icon: Icons.numbers,
          isInForm: true,
        ),
        FieldConfig(
          label: "Bairro",
          fieldName: "endereco.bairro",
          icon: Icons.location_city,
          isInForm: true,
        ),
        FieldConfig(
          label: "CEP",
          fieldName: "endereco.cep",
          icon: Icons.markunread_mailbox,
          isInForm: true,
        ),
      ],
    ),
    TabConfig(
      title: "Logins",
      icon: Icons.history,
      isGrid: true,
      endpoint: ApiLinks.allLogins,
      gridFieldConfigs: Login.fieldConfigs,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen<Parceiro>(
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
