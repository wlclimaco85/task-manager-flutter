import 'package:flutter/material.dart';
import '../../web/screens/alvara_grid_screen.dart';

/// Tela mobile de Alvarás — reutiliza o mesmo widget Web/Windows.
class MobileAlvaraScreen extends StatelessWidget {
  const MobileAlvaraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WebAlvaraGridScreen(hasPermission: (_) => true);
  }
}
