import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:task_manager_flutter/data/models/grupo_muscular_model.dart';

class GrupoMuscularGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const GrupoMuscularGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<GrupoMuscular>(
      title: "Grupos Musculares",
      fetchEndpoint: ApiLinks.allGruposMusculares,
      createEndpoint: ApiLinks.createGrupoMuscular,
      updateEndpoint: ApiLinks.updateGrupoMuscular(":id"),
      deleteEndpoint: ApiLinks.deleteGrupoMuscular(":id"),
      fromJson: (json) => GrupoMuscular.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: GrupoMuscular.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'grupos_musculares',
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
