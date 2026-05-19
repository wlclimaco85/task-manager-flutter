import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/personal_model.dart';

class WindowsPersonalGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsPersonalGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<PersonalDto>(
      telaNome: 'Personal', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => PersonalDto.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}
