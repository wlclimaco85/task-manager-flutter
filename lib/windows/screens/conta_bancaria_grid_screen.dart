import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_bancaria_model.dart';

class WindowsContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsContaBancariaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaBancaria>(
      telaNome: 'ContaBancaria',
      hasPermission: hasPermission,
      fromJson: (json) => ContaBancaria.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
