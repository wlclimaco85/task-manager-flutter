import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../windows/screens/details/parceiro_detail_screen.dart';

class WindowsParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => WindowsParceiroDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
