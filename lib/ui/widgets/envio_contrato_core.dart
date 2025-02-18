import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/services/checkout_caller.dart';
import 'package:task_manager_flutter/ui/screens/negociacao_screen.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

// Define cores
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color mediumGreenBackground = Color.fromARGB(255, 200, 230, 200);
const Color darkGreenBorder = Color(0xFF2E7D32);

class RenegotiationMovimentoContratosHandler {
  static Future<bool> renegotiates({
    required BuildContext context,
    required int vendaId,
    required String status,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Future<void> _downloadContract(int contratoId, BuildContext context) async {
      try {
        bool success =
            await CheckoutCaller().downloadContrato(contratoId, context);

        if (success) {
          // Fecha todos os diálogos abertos
          Navigator.of(context).popUntil((route) => route.isFirst);

          // Mostra feedback de sucesso
          _showSnackBar(
            context,
            message: "Contrato baixado com sucesso.",
            isError: false,
          );

          // Navega para a tela de negociação
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NegociacaoCatalogPage(
                title: 'Negociação',
                apiUrl:
                    '${ApiLinks.negociacaoFindByUser}${AuthUtility.userInfo?.data?.id}',
                actionIcon: Icons.edit,
                actionTooltip: 'Editar Produto',
              ),
            ),
          );
        } else {
          _showSnackBar(
            context,
            message: "Erro ao baixar contrato.",
            isError: true,
          );
        }
      } catch (e) {
        _showSnackBar(
          context,
          message: "Erro: ${e.toString()}",
          isError: true,
        );
      }
    }

    Future<void> _uploadContract(int negociacaoID) async {
      try {
        CheckoutCaller.uploadContract(negociacaoID);
      } catch (e) {}
    }

    try {
      // Fecha o diálogo de carregamento antes de abrir o novo popup
      Navigator.of(context).pop();

      try {
        void _showDownloadAndUploadButtons() {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: lightGreenBackground,
                title: const Text('Contrato',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: darkGreenBorder)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'download' || status == 'both')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 24),
                          label: const Text('Baixar Contrato Modelo',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreenBorder,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: darkGreenBorder),
                            ),
                          ),
                          onPressed: () => _downloadContract(vendaId, context),
                        ),
                      ),
                    if (status == 'upload' || status == 'both')
                      SizedBox(height: 15),
                    if (status == 'upload' || status == 'both')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload, size: 24),
                          label: const Text('Enviar Contrato Assinado',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkGreenBorder,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: darkGreenBorder),
                            ),
                          ),
                          onPressed: () => _uploadContract(vendaId),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkGreenBorder)),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: const BorderSide(color: darkGreenBorder, width: 2),
                ),
              );
            },
          );
        }

        _showDownloadAndUploadButtons();

        return true;
      } catch (e) {
        Navigator.of(context).pop();
        _showSnackBar(
          context,
          message: "Erro: ${e.toString()}",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar(context, message: "Erro: ${e.toString()}", isError: true);
      return false;
    }
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
