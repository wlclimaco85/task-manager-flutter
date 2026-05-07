import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class ComunicadoScreen extends StatelessWidget {
  const ComunicadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'comunicado',
      hasPermission: (_) => true,
    );
  }
}
