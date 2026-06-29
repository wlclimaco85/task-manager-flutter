import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/mensalidade_model.dart';
import '../../../widgets/importacao_boletos_dialog.dart';

class WindowsMensalidadeGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  const WindowsMensalidadeGridScreen({super.key, required this.hasPermission});

  @override
  State<WindowsMensalidadeGridScreen> createState() => _WindowsMensalidadeGridScreenState();
}

class _WindowsMensalidadeGridScreenState extends State<WindowsMensalidadeGridScreen> {
  int _chaveReload = 0;

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Mensalidade>(
      key: ValueKey(_chaveReload),
      telaNome: 'Mensalidades',
      hasPermission: widget.hasPermission,
      fromJson: (json) => Mensalidade.fromJson(json),
      toJson: (item) => item.toJson(),
      headerActions: [
        OutlinedButton.icon(
          onPressed: () => _importarBoletos(),
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Importar Boletos'),
        ),
      ],
    );
  }

  void _importarBoletos() {
    showDialog(
      context: context,
      builder: (_) => ImportacaoBoletosDialog(
        onSuccess: () => setState(() => _chaveReload++),
      ),
    );
  }
}
