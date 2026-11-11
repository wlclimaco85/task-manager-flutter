import 'package:flutter/material.dart';

import '../../widgets/relatorio_construtor_view.dart';
import '../../widgets/relatorios_personalizados_view.dart';

/// Relatórios no Mobile: a mesma tela de Web/Windows, em coluna vertical.
class MobileRelatoriosPersonalizadosScreen extends StatelessWidget {
  const MobileRelatoriosPersonalizadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatórios')),
      body: const SafeArea(child: RelatoriosPersonalizadosView()),
    );
  }
}

/// Construtor de Relatórios no Mobile (MASTER).
class MobileRelatorioConstrutorScreen extends StatelessWidget {
  const MobileRelatorioConstrutorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Construtor de Relatórios')),
      body: const SafeArea(child: RelatorioConstrutorView()),
    );
  }
}
