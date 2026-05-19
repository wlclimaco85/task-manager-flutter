import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../../utils/security_matrix.dart';

class ChamadosScreenDinamic extends StatelessWidget {
  const ChamadosScreenDinamic({super.key});

  bool _hasPermission(String permission) {
    final sec = SecurityMatrix.current();
    final lower = permission.toLowerCase();
    if (lower.contains('create') || lower.contains('insert')) {
      return sec.canInsert(AppScreen.chamados);
    }
    if (lower.contains('edit') || lower.contains('update')) {
      return sec.canUpdate(AppScreen.chamados);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return sec.canDelete(AppScreen.chamados);
    }
    if (lower.contains('view') ||
        lower.contains('read') ||
        lower.contains('list')) {
      return sec.canView(AppScreen.chamados);
    }
    return sec.hasAnyAccess(AppScreen.chamados);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'chamados',
      hasPermission: _hasPermission,
    );
  }
}
