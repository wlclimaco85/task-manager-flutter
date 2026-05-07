import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../web/screens/nfe_grid_screen.dart' show WebNfeGridScreen;

class WindowsNotaFiscalEntradaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsNotaFiscalEntradaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    // Reutiliza a tela Web que já tem o layout correto (header + filtros + grid)
    return const WebNfeGridScreen(entrada: true);
  }
}
