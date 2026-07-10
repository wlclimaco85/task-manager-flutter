import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/chamado_model.dart';
// 🔥 Importa só o CustomAction do grid do Windows
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../widgets/chamado_detalhe_screen.dart';
import '../../../windows/screens/fechar_chamado_dialog.dart';

class WindowsChamadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsChamadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Chamado>(
      telaNome: 'Chamados', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => Chamado.fromJson(json),
      toJson: (a) => a.toJson(),

      // Card #451: abre a tela de detalhe/timeline do chamado.
      detailScreenBuilder: (chamado) =>
          ChamadoDetalheScreen(chamado: chamado),

      // 🔥 AQUI entram os botões extras por linha
      customActions: () => [
        CustomAction<Chamado>(
          icon: Icons.check_circle,
          label: 'Fechar',
          onPressed: (context, chamado) => _showFecharDialog(context, chamado),

          // opcional: só mostra se ainda não estiver fechado
          // ajusta de acordo com o seu modelo
          isVisible: (chamado) {
            // exemplo genérico, muda conforme seu ChamadoModel:
            // return chamado.status != 'FECHADO';
            return true;
          },
        ),
      ],
    );
  }

  void _showFecharDialog(BuildContext context, Chamado chamado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FecharChamadoDialog(
          chamadoId: chamado.id ?? 0, // ajusta se id não for nullable
        );
      },
    );
  }
}
