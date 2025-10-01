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
        useUserBannerAppBar: true,
        fromJson: (json) => Chamado.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        hasPermission: hasPermission,
        fieldConfigs: _getFieldConfigsWithFilters(), // Configuração corrigida
        idFieldName: 'id',
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        enableSearch: true,
        storageKey: 'chamados_grid', // CHAVE DE ARMAZENAMENTO
        customActions: () => [
          CustomAction<Chamado>(
            icon: Icons.assignment_turned_in,
            label: 'Fechar Chamado',
            onPressed: (context, item) {
              _showCloseChamadoDialog(context, [item]);
            },
          ),
        ],
      ),
    );
  }

  List<FieldConfig> _getFieldConfigsWithFilters() {
    return [
      FieldConfig(
        label: 'ID',
        fieldName: 'id',
        fieldType: FieldType.text,
        isFilterable: true, // Filter is enabled
        isInForm: false,
        isVisibleByDefault: true,
      ),
      FieldConfig(
        label: 'Título',
        fieldName: 'titulo',
        fieldType: FieldType.text,
        isFilterable: true, // Filter is enabled
        isInForm: true,
        isVisibleByDefault: true,
      ),
      FieldConfig(
        label: 'Status',
        fieldName: 'status',
        fieldType: FieldType.dropdown,
        isFilterable: true, // Filter is enabled
        isInForm: true,
        isVisibleByDefault: true,
        dropdownOptions: [
          // Simple local options
          {'value': 'aberto', 'label': 'Aberto'},
          {'value': 'fechado', 'label': 'Fechado'},
        ],
      ),
    ];
  }

  // FILTROS INICIAIS (OPCIONAL)
  Map<String, dynamic> _getInitialFilters() {
    return {
      'status': 'aberto', // Filtra apenas chamados abertos por padrão
      // 'prioridade': 'alta', // Descomente para filtrar por prioridade específica
    };
  }

  void _showCloseChamadoDialog(
      BuildContext context, List<Chamado> selectedItems) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fechar Chamados'),
        content: Text('Deseja fechar ${selectedItems.length} chamado(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _fecharChamados(selectedItems);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chamados fechados com sucesso!')),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _fecharChamados(List<Chamado> chamados) {
    // Implementar a lógica de fechamento dos chamados
    for (var chamado in chamados) {
      // Lógica para fechar cada chamado
      print('Fechando chamado: ${chamado.id}');
    }
  }
}
