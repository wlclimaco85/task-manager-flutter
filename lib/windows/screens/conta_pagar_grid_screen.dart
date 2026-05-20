// conta_pagar_grid_screen.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../windows/screens/baixa_dialog.dart';
import 'package:http/http.dart' as http;

class WindowsContaPagarGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const WindowsContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  State<WindowsContaPagarGridScreen> createState() =>
      _WindowsContaPagarGridScreenState();
}

class _WindowsContaPagarGridScreenState
    extends State<WindowsContaPagarGridScreen> {
  bool _importing = false;

  Future<void> _importarBoleto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      _snack('Nao foi possivel ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiLinks.importacaoContaPagar),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: file.name),
      );
      if (TenantContext.empresaId != null) {
        request.fields['empresaId'] = TenantContext.empresaId.toString();
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final importados = data['importados'] ?? data['count'] ?? '?';
        _snack('ImportaÃ§Ã£o concluÃ­da: $importados registro(s)');
      } else {
        _snack('Erro na importaÃ§Ã£o (${response.statusCode})', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ContaPagar>(
      telaNome: 'conta_pagar',
      hasPermission: widget.hasPermission,
      fromJson: (json) => ContaPagar.fromJson(json),
      toJson: (a) => a.toJson(),
      fetchEndpointOverride: ApiLinks.allContasPagar,
      createEndpointOverride: ApiLinks.createContaPagar,
      updateEndpointOverride: ApiLinks.updateContaPagar(':id'),
      deleteEndpointOverride: ApiLinks.deleteContaPagar(':id'),
      fieldOverrides: const [
        FieldConfigWindows(
            fieldName: 'parceiro',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),
        FieldConfigWindows(
            fieldName: 'parceiroDev',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),
        FieldConfigWindows(
            fieldName: 'parceiroRec',
            label: '',
            isInForm: false,
            isVisibleByDefault: false,
            enabled: false),
      ],
      headerActions: [
        OutlinedButton.icon(
          onPressed: _importing ? null : _importarBoleto,
          icon: _importing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: GridColors.secondary),
                )
              : const Icon(Icons.upload_file, size: 18),
          label: const Text('Importar Boleto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: GridColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: const BorderSide(color: GridColors.divider),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
      customActions: () => [
        CustomAction<ContaPagar>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (_) => true,
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
