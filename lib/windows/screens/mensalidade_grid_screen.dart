import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/mensalidade_model.dart';

class WindowsMensalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsMensalidadeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Mensalidade>(
      telaNome: 'Mensalidades',
      hasPermission: hasPermission,
      fromJson: (json) => Mensalidade.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}
