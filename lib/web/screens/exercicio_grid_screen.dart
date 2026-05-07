import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/exercicio_model.dart';
import '../../../utils/dropdown_helpers.dart';

class WebExercicioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebExercicioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Exercicio>(
      telaNome: 'exercicio',
      hasPermission: hasPermission,
      fromJson: (json) => Exercicio.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.grupoMuscularField(),
      ],
    );
  }
}
