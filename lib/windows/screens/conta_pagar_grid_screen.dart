// conta_pagar_grid_screen.dart
import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../windows/screens/baixa_dialog.dart';

class WindowsContaPagarGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaPagar>(
      telaNome: 'conta_pagar', // nome da tela no banco
      hasPermission: hasPermission,
      fromJson: (json) => ContaPagar.fromJson(json),
      toJson: (a) => a.toJson(),

      // 🔥 AQUI entram os botões extras por linha
      customActions: () => [
        CustomAction<ContaPagar>(
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

  void _showBaixaDialog(BuildContext context, ContaPagar conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BaixaDialog(conta: conta);
      },
    );
  }
}
