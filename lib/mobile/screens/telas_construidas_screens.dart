import 'package:flutter/material.dart';

import '../../utils/abrir_tela_construida.dart';
import '../../widgets/construtor_telas_view.dart';

/// Construtor de Telas no Mobile (mesma tela de Web/Windows, em coluna vertical).
class MobileConstrutorTelasScreen extends StatelessWidget {
  const MobileConstrutorTelasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Construtor de Telas')),
      body: const SafeArea(child: ConstrutorTelasView(abrir: abrirTelaConstruidaMobile)),
    );
  }
}

/// Telas Personalizadas no Mobile.
class MobileTelasPersonalizadasScreen extends StatelessWidget {
  const MobileTelasPersonalizadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telas Personalizadas')),
      body: const SafeArea(child: TelasPersonalizadasView(abrir: abrirTelaConstruidaMobile)),
    );
  }
}
