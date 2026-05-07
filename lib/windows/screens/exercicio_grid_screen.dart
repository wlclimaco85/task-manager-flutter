import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/exercicio_model.dart';

class WindowsExercicioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsExercicioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Exercicio>(
      telaNome: 'Exercícios', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Exercicio.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
