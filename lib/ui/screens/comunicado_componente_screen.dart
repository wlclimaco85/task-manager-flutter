import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_flutter/data/models/comunicados_model.dart';

class ComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Comunicado>(
      title: "Comunicados",
      fetchEndpoint: ApiLinks.allComunicados,
      createEndpoint: ApiLinks.createComunicado,
      updateEndpoint: ApiLinks.updateComunicado(":id"),
      deleteEndpoint: ApiLinks.deleteComunicado(":id"),
      fromJson: (json) => Comunicado.fromJson(json),
      toJson: (comunicado) => comunicado.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Comunicado.fieldConfigs,
      idFieldName: '_id', // Nome do campo ID no JSON
      dateFieldName: 'dhCreatedAt', // Nome do campo data no JSON
    );
  }
}
