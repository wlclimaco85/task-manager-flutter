import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/nfce_model.dart';
import '../../../services/nfce_service.dart';
import '../../../services/print_service_nfce.dart';
import '../../../utils/app_snackbar.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;

class WebNfceGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNfceGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<NfceModel>(
      telaNome: 'nfce',
      tituloOverride: 'NFC-e / Cupons',
      hasPermission: hasPermission,
      fromJson: (json) => NfceModel.fromJson(json),
      toJson: (a) => a.toJson(),
      customActions: () => [
        CustomAction<NfceModel>(
          label: 'Consultar status',
          icon: Icons.manage_search,
          onPressed: _consultarStatus,
        ),
        CustomAction<NfceModel>(
          label: 'Cancelar',
          icon: Icons.cancel,
          onPressed: _cancelar,
        ),
        CustomAction<NfceModel>(
          label: 'Cancelar por substituição',
          icon: Icons.change_circle,
          onPressed: (context, _) {
            AppSnackbar.error(
              context,
              'Cancelamento por substituição ainda não possui endpoint ativo.',
            );
          },
        ),
        CustomAction<NfceModel>(
          label: 'Contingência / EPEC',
          icon: Icons.podcasts,
          onPressed: _reenviarContingencia,
        ),
        CustomAction<NfceModel>(
          label: 'Inutilizar numeração',
          icon: Icons.block,
          onPressed: _inutilizar,
        ),
        CustomAction<NfceModel>(
          label: 'Gerar PDF',
          icon: Icons.picture_as_pdf,
          onPressed: _gerarPdf,
        ),
        CustomAction<NfceModel>(
          label: 'Baixar XML',
          icon: Icons.code,
          onPressed: _baixarXml,
        ),
        CustomAction<NfceModel>(
          label: 'Enviar e-mail',
          icon: Icons.email,
          onPressed: _enviarEmail,
        ),
      ],
    );
  }

  static Future<void> _consultarStatus(
    BuildContext context,
    NfceModel nfce,
  ) async {
    try {
      final status = await NfceService().consultarStatus(nfce.id);
      if (!context.mounted) return;
      _showDataDialog(context, 'Status NFC-e', {
        'id': status.id,
        'status': status.status,
        'mensagem': status.mensagem ?? '-',
        'protocolo': status.protocolo ?? '-',
        'codigoRetorno': status.codigoRetorno ?? '-',
        'motivoRejeicao': status.motivoRejeicao ?? '-',
      });
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao consultar status: $e');
      }
    }
  }

  static Future<void> _cancelar(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Cancelar NFC-e',
      label: 'Justificativa',
      hint: 'Mínimo 15 caracteres',
      initialValue: 'Cancelamento solicitado pela listagem',
    );
    if (justificativa == null) return;
    try {
      await NfceService().cancelarNfce(
        nfce.id,
        justificativa,
        empresaId: TenantContext.empresaId ?? 0,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e cancelada com sucesso.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao cancelar: $e');
    }
  }

  static Future<void> _reenviarContingencia(
    BuildContext context,
    NfceModel nfce,
  ) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await NfceService().reenviarContingencia(nfce.id);
      if (context.mounted) {
        AppSnackbar.success(context, 'NFC-e enviada em contingência.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar contingência: $e');
      }
    }
  }

  static Future<void> _inutilizar(BuildContext context, NfceModel nfce) async {
    if (nfce.numero == null || nfce.serie == null) {
      AppSnackbar.error(context, 'NFC-e sem número ou série.');
      return;
    }
    final justificativa = await _promptText(
      context,
      title: 'Inutilizar numeração',
      label: 'Justificativa',
      hint: 'Explique o motivo da inutilização',
    );
    if (justificativa == null) return;
    try {
      await NfceService().inutilizar(
        empresaId: TenantContext.empresaId ?? 0,
        uf: 'MG',
        ambiente: 'HOMOLOGACAO',
        serie: nfce.serie!,
        numeroInicio: nfce.numero!,
        numeroFim: nfce.numero!,
        justificativa: justificativa,
      );
      if (context.mounted) {
        AppSnackbar.success(context, 'Numeração inutilizada.');
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao inutilizar: $e');
    }
  }

  static Future<void> _gerarPdf(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      await PrintServiceNfce().imprimirDanfe(context, nfce.id);
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao gerar PDF: $e');
    }
  }

  static Future<void> _baixarXml(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    try {
      final xml = await NfceService().baixarXml(nfce.id);
      await FileSaver.instance.saveFile(
        name: 'nfce_${nfce.id}',
        bytes: xml,
        fileExtension: 'xml',
      );
      if (context.mounted) AppSnackbar.success(context, 'XML baixado.');
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, 'Erro ao baixar XML: $e');
    }
  }

  static Future<void> _enviarEmail(BuildContext context, NfceModel nfce) async {
    if (nfce.id == 0) {
      AppSnackbar.error(context, 'NFC-e sem ID.');
      return;
    }
    final email = await _promptText(
      context,
      title: 'Enviar NFC-e por e-mail',
      label: 'E-mail',
      hint: 'destinatario@empresa.com',
      minLength: 5,
    );
    if (email == null) return;
    try {
      await NfceService().enviarEmail(nfce.id, email);
      if (context.mounted) {
        AppSnackbar.success(context, 'E-mail enviado com sucesso.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao enviar e-mail: $e');
      }
    }
  }

  static Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String label,
    String? hint,
    String? initialValue,
    int minLength = 15,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: label == 'E-mail' ? 1 : 3,
          keyboardType: label == 'E-mail'
              ? TextInputType.emailAddress
              : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (value == null) return null;
    if (value.length < minLength) {
      if (context.mounted) {
        AppSnackbar.error(
          context,
          '$label deve ter pelo menos $minLength caracteres.',
        );
      }
      return null;
    }
    return value;
  }

  static void _showDataDialog(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('${e.key}: ${e.value}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
