import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card_1_0.dart';
import 'package:task_manager_flutter/data/models/chamado_model.dart';
import 'package:task_manager_flutter/data/services/auth_service.dart';

class ChamadosScreenDinamic extends StatelessWidget {
  const ChamadosScreenDinamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen<Chamado>(
      telaNome: 'chamados', // ← APENAS ISSO!
      fromJson: (json) => Chamado.fromJson(json),
      toJson: (chamado) => chamado.toJson(),
      hasPermission: (permission) => AuthService().hasPermission(permission),
    );
  }
}
