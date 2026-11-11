import 'package:flutter/material.dart';

import '../customization/dynamic_grid_dynamic_screen.dart';
import '../customization/dynamic_grid_windows_screen.dart';
import '../services/construtor_telas_service.dart';

/// Abre uma tela criada no Construtor com a grid dinamica de Web/Windows (CRUD generico /api/dados/{tabela}).
void abrirTelaConstruidaWindows(BuildContext context, TelaConstruida tela) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(tela.titulo)),
      body: DynamicGridWindowsScreen<Map<String, dynamic>>(
        telaNome: tela.telaNome,
        hasPermission: (_) => true, // o servidor valida tenant e tela ativa; acesso ao menu e do Controle de Acesso
        fromJson: (m) => m,
        toJson: (m) => m,
        showAppBar: false,
      ),
    ),
  ));
}

/// Abre a mesma tela com a grid dinamica do Mobile (cartoes, layout vertical).
void abrirTelaConstruidaMobile(BuildContext context, TelaConstruida tela) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => DynamicGridDynamicScreen(
      telaNome: tela.telaNome,
      hasPermission: (_) => true,
      tituloOverride: tela.titulo,
    ),
  ));
}
