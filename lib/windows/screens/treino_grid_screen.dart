import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/treino_model.dart';

class WindowsTreinoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsTreinoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Treino>(
      telaNome: 'Treino',
      hasPermission: hasPermission,
      fromJson: (json) => Treino.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
