import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../windows/screens/details/empresa_detail_screen.dart';

class WindowsEmpresaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsEmpresaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'empresa',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => WindowsEmpresaDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
