import 'package:flutter/material.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/treino_model.dart';

class WebTreinoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTreinoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Treino>(
      telaNome: 'treino',
      hasPermission: hasPermission,
      fromJson: (json) => Treino.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}


