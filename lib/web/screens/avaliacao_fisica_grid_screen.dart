import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/avaliacao_fisica_model.dart';

class WebAvaliacaoFisicaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebAvaliacaoFisicaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<AvaliacaoFisica>(
      telaNome: 'avaliacao_fisica',
      hasPermission: hasPermission,
      fromJson: (json) => AvaliacaoFisica.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}


