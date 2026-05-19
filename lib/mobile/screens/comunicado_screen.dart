import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../../utils/security_matrix.dart';

class ComunicadoScreen extends StatelessWidget {
  const ComunicadoScreen({super.key});

  bool _hasPermission(String permission) {
    final sec = SecurityMatrix.current();
    final lower = permission.toLowerCase();
    if (lower.contains('create') || lower.contains('insert')) {
      return sec.canInsert(AppScreen.comunicados);
    }
    if (lower.contains('edit') || lower.contains('update')) {
      return sec.canUpdate(AppScreen.comunicados);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return sec.canDelete(AppScreen.comunicados);
    }
    if (lower.contains('view') ||
        lower.contains('read') ||
        lower.contains('list')) {
      return sec.canView(AppScreen.comunicados);
    }
    return sec.hasAnyAccess(AppScreen.comunicados);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'comunicado',
      hasPermission: _hasPermission,
    );
  }
}
