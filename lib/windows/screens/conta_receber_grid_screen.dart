// conta_receber_grid_screen.dart
import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_receber_model.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../windows/screens/baixa_dialog_receber.dart';

class WindowsContaReceberGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsContaReceberGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaReceber>(
      telaNome: 'conta_receber', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => ContaReceber.fromJson(json),
      toJson: (a) => a.toJson(),

      // 🔥 AQUI entram os botões extras por linha
      customActions: () => [
        CustomAction<ContaReceber>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),

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

  void _showBaixaDialog(BuildContext context, ContaReceber conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialogReceber(conta: conta);
      },
    );
  }
}
