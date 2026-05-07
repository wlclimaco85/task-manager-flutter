import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import 'details/parceiro_detail_screen.dart';

class WebParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'parceiro',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => WebParceiroDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
