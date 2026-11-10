import 'package:flutter/material.dart';

import '../../widgets/modulo_java_view.dart';

/// Módulo Java no Mobile: a mesma tela de Web/Windows, em coluna vertical (lista e detalhe se alternam).
class MobileModuloJavaScreen extends StatelessWidget {
  const MobileModuloJavaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Módulo Java')),
      body: const SafeArea(child: ModuloJavaView()),
    );
  }
}
