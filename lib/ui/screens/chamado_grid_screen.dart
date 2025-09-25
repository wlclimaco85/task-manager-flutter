// lib/ui/screens/chamado_grid_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';

class ChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<Chamado>(
        title: "Gerenciamento de Chamados",
        fetchEndpoint: ApiLinks.allChamados,
        createEndpoint: ApiLinks.createChamado,
        updateEndpoint: ApiLinks.updateChamado(":id"),
        deleteEndpoint: ApiLinks.deleteChamado(":id"),
        fromJson: (json) => Chamado.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        hasPermission: hasPermission,
        fieldConfigs: Chamado.fieldConfigs,
        idFieldName: 'id',
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        enableSearch: true,
        customActions: () => [
          // A função deve retornar uma List<CustomAction<Chamado>>
          CustomAction<Chamado>(
            icon: Icons.assignment_turned_in,
            label: 'Fechar Chamado',
            onPressed: (context, item) {
              // Sua lógica para fechar o chamado aqui
            },
          ),
        ],
      ),
    );
  }

  void _showCloseChamadoDialog(
      BuildContext context, List<dynamic> selectedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fechar Chamados'),
        content: Text('Deseja fechar ${selectedItems.length} chamado(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implementar lógica de fechamento
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chamados fechados com sucesso!')),
              );
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
