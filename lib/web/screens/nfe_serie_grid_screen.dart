import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebNfeSerieGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNfeSerieGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'nfe_serie', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}
