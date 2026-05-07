import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import 'details/empresa_detail_screen.dart';

class WebEmpresaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebEmpresaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'empresa',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => WebEmpresaDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
