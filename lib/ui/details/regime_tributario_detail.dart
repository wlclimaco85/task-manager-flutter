import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/regime_tributario_model.dart';
import 'package:task_manager_flutter/ui/widgets/genericDetailFormScreen.dart';
import 'package:task_manager_flutter/ui/widgets/generic_grid_screen.dart';

class RegimeDetailScreen extends StatelessWidget {
  final RegimeTributario item;
  final SecurityCheck hasPermission;

  const RegimeDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericDetailFormScreen<RegimeTributario>(
      item: item,
      tabConfigs: RegimeTributario.tabConfigs,
      title: "Detalhes Regime Tributário",
      onSave: (formData) async {
        print("Salvar regime: $formData");
        // chamada POST/PUT
      },
      onBack: () => Navigator.pop(context),
      hasPermission: hasPermission, // Adicionar este parâmetro
    );
  }
}
