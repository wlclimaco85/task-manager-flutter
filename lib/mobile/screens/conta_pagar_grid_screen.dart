import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../widgets/anexo_financeiro_widget.dart';
import '../screens/baixa_dialog.dart';
import '../screens/desfazer_baixa_dialog.dart';

class ContaPagarGridScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const ContaPagarGridScreen({super.key, required this.hasPermission});

  @override
  State<ContaPagarGridScreen> createState() => _ContaPagarGridScreenState();
}

class _ContaPagarGridScreenState extends State<ContaPagarGridScreen> {
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GenericMobileGridScreen<ContaPagar>(
          title: "Contas a Pagar",
          fetchEndpoint: ApiLinks.allContasPagar,
          createEndpoint: ApiLinks.createContaPagar,
          updateEndpoint: ApiLinks.updateContaPagar(":id"),
          deleteEndpoint: ApiLinks.deleteContaPagar(":id"),
          fromJson: (json) => ContaPagar.fromJson(json),
          toJson: (obj) => obj.toJson(),
          hasPermission: widget.hasPermission,
          fieldConfigs: ContaPagar.fieldConfigs,
          idFieldName: 'id',
          dateFieldName: 'audit.createdAt',
          customActions: () => [
            CustomAction<ContaPagar>(
              icon: Icons.payment,
              label: 'Baixar',
              onPressed: (context, object) => _showBaixaDialog(context, object),
              isVisible: (object) => object.status == StatusConta.ABERTA,
            ),
            CustomAction<ContaPagar>(
              icon: Icons.undo,
              label: 'Desfazer Baixa',
              isVisible: (obj) => obj.status == StatusConta.BAIXADA,
              onPressed: (context, object) {
                DesfazerBaixaDialog.show(
                  context,
                  tipo: 'pagar',
                  contaId: object.id!,
                  dataBaixa: object.dataBaixa ?? DateTime.now(),
                  valorBaixa: object.valorBaixa ?? object.valor,
                  contaLabel: object.contaBaixa?.descricao ?? 'Conta nao informada',
                  formaPagamentoLabel:
                      object.formaPagamento?.nome ?? 'Forma nao informada',
                );
              },
            ),
            CustomAction<ContaPagar>(
              icon: Icons.attach_file,
              label: 'Anexos',
              isVisible: (obj) => obj.id != null,
              onPressed: (context, object) => _showAnexos(context, object),
            ),
          ],
          useUserBannerAppBar: true,
          paginationConfig: const PaginationConfig(
            defaultRowsPerPage: 10,
            availableRowsPerPage: [10, 25, 50],
          ),
          enableSearch: true,
        ),
        // FAB de importacao — posicionado sobre o GenericMobileGridScreen
        Positioned(
          bottom: 88,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'fab_import_conta_pagar',
            tooltip: 'Importar extrato (CSV/REM/RET)',
            backgroundColor: GridColors.primary,
            onPressed: _importing ? null : _importarBoleto,
            child: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Future<void> _importarBoleto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'rem', 'ret', 'txt'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final file = result.files.first;
    var bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }
    if (bytes == null) {
      _snack('Nao foi possivel ler o arquivo', error: true);
      return;
    }

    setState(() => _importing = true);
    try {
      final importUrl = TenantContext.empresaId == null
          ? ApiLinks.importacaoContaPagar
          : '${ApiLinks.importacaoContaPagar}?empId=${TenantContext.empresaId}';
      final request = http.MultipartRequest('POST', Uri.parse(importUrl));
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('arquivo', bytes, filename: file.name),
      );
      if (TenantContext.empresaId != null) {
        request.fields['empId'] = TenantContext.empresaId.toString();
        request.fields['empresaId'] = TenantContext.empresaId.toString();
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        final importados = data['importados'] ?? data['count'] ?? '?';
        _snack('Importacao concluida: $importados registros');
      } else {
        _snack('Erro ao importar: status ${response.statusCode}', error: true);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  void _showAnexos(BuildContext context, ContaPagar conta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: AnexoFinanceiroWidget(
          lancamentoId: conta.id!,
          lancamentoTipo: 'PAGAR',
        ),
      ),
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
