import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import 'details/funcionario_detail_screen.dart';

class WebFuncionarioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebFuncionarioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'funcionario',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (f) => f,
      detailScreenBuilder: (item) => WebFuncionarioDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
