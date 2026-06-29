import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_dynamic_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/security_matrix.dart';

/// Tela stub para formulário de nova Nota de Serviço (NFS-e).
/// Reusa DynamicGridDynamicScreen em modo "create only" (sem listagem).
class NfseServicoScreen extends StatelessWidget {
  final Function(String action)? hasPermission;

  const NfseServicoScreen({
    super.key,
    this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Nota de Serviço'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Formulário de NFS-e em desenvolvimento'),
      ),
    );
  }
}
