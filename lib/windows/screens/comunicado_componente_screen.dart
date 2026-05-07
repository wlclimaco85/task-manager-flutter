import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart'
    show DynamicGridWindowsScreen, SecurityCheck;

class WindowsComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'comunicado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
    );
  }
}
