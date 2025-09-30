import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/fechar_chamado_dialog.dart';

class ChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Chamado>(
      title: "Chamados",
      fetchEndpoint: ApiLinks.allChamados,
      createEndpoint: ApiLinks.createChamado,
      updateEndpoint: ApiLinks.updateChamado(":id"),
      deleteEndpoint: ApiLinks.deleteChamado(":id"),
      fromJson: (json) => Chamado.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Chamado.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'chamados',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
      customActions: () => [
        CustomAction<Chamado>(
          icon: Icons.check_circle,
          label: 'Fechar',
          onPressed: (context, object) => _showFecharDialog(context, object),
        ),
      ],
    );
  }

  void _showFecharDialog(BuildContext context, Chamado chamado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FecharChamadoDialog(chamadoId: chamado?.id ?? 0);
      },
    );
  }
}
