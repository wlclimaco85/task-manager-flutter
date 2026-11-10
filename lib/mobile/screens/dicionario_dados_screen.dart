import 'package:flutter/material.dart';

import '../../widgets/dicionario_dados_view.dart';

/// Dicionário de Dados no Mobile: a mesma tela de Web/Windows, em coluna vertical.
class MobileDicionarioDadosScreen extends StatelessWidget {
  const MobileDicionarioDadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dicionário de Dados')),
      body: const SafeArea(child: DicionarioDadosView()),
    );
  }
}
