import 'package:flutter/material.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_bancaria_model.dart';

class WebContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebContaBancariaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaBancaria>(
      telaNome: 'conta_bancaria',
      hasPermission: hasPermission,
      fromJson: (json) => ContaBancaria.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
        DropdownHelpers.parceiroField(),
      ],
    );
  }
}
