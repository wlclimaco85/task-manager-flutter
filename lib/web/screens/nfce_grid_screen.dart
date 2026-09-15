import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../models/nfce_model.dart';
import '../../../services/nfce_service.dart';
import '../../../utils/app_snackbar.dart';
import '../../../services/print_service_nfce.dart';
import '../../../utils/tenant_context.dart';

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
          label: 'Cancelar',
          icon: Icons.cancel,
          onPressed: (BuildContext context, NfceModel nfce) async {
            try {
              if (nfce.id == null) {
                AppSnackbar.error(context, 'NFC-e sem ID.');
                return;
              }
              final service = NfceService();
              await service.cancelarNfce(nfce.id!, "Cancelamento via listagem", empresaId: TenantContext.empresaId ?? 0);
              AppSnackbar.success(context, 'NFC-e cancelada com sucesso!');
            } catch (e) {
              AppSnackbar.error(context, 'Erro ao cancelar: $e');
            }
          },
        ),
        CustomAction<NfceModel>(
          label: 'ContingǦncia',
          icon: Icons.podcasts,
          onPressed: (BuildContext context, NfceModel nfce) async {
            try {
              if (nfce.id == null) {
                AppSnackbar.error(context, 'NFC-e sem ID.');
                return;
              }
              final service = NfceService();
              await service.reenviarContingencia(nfce.id!);
              AppSnackbar.success(context, 'NFC-e enviada em contingǦncia!');
            } catch (e) {
              AppSnackbar.error(context, 'Erro ao enviar contingǦncia: $e');
            }
          },
        ),
        CustomAction<NfceModel>(
          label: 'Gerar PDF',
          icon: Icons.picture_as_pdf,
          onPressed: (BuildContext context, NfceModel nfce) async {
            try {
              if (nfce.id == null) {
                AppSnackbar.error(context, 'NFC-e sem ID.');
                return;
              }
              await PrintServiceNfce().imprimirDanfe(context, nfce.id!);
            } catch (e) {
              AppSnackbar.error(context, 'Erro ao gerar PDF: $e');
            }
          },
        ),
        CustomAction<NfceModel>(
          label: 'Enviar Email',
          icon: Icons.email,
          onPressed: (BuildContext context, NfceModel nfce) async {
            if (nfce.id == null) {
              AppSnackbar.error(context, 'NFC-e sem ID.');
              return;
            }
            final emailController = TextEditingController();
            final result = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Enviar NFC-e por Email'),
                content: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: "Digite o email do destinatǭrio"),
                  keyboardType: TextInputType.emailAddress,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, emailController.text),
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            );

            if (result != null && result.isNotEmpty) {
              try {
                final service = NfceService();
                await service.enviarEmail(nfce.id!, result);
                AppSnackbar.success(context, 'Email enviado com sucesso!');
              } catch (e) {
                AppSnackbar.error(context, 'Erro ao enviar email: $e');
              }
            }
          },
        ),
      ],
    );
  }
}
