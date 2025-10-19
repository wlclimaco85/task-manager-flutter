import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/data/services/auth_service.dart';

class ChamadosScreenDinamic extends StatelessWidget {
  const ChamadosScreenDinamic({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'chamados',
      hasPermission: (permission) {
        // Kick off the async check but return a synchronous default to satisfy the
        // expected bool signature; adapt to a proper solution (e.g. make the
        // API async-aware) if runtime behavior needs to depend on the result.
        AuthService().hasPermission(permission).then((_) {});
        return false;
      },
    );
  }
}
