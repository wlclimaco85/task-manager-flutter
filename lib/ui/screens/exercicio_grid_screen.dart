import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/exercicio_model.dart';

class ExercicioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ExercicioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Exercicio>(
      title: "Exercícios",
      fetchEndpoint: ApiLinks.allExercicios,
      createEndpoint: ApiLinks.createExercicio,
      updateEndpoint: ApiLinks.updateExercicio(":id"),
      deleteEndpoint: ApiLinks.deleteExercicio(":id"),
      fromJson: (json) => Exercicio.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Exercicio.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'exercicios',
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
