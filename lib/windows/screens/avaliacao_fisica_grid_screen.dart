import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/avaliacao_fisica_model.dart';

class WindowsAvaliacaoFisicaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsAvaliacaoFisicaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<AvaliacaoFisica>(
      telaNome: 'AvaliacaoFisica',
      hasPermission: hasPermission,
      fromJson: (json) => AvaliacaoFisica.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
