import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_manager_flutter/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/models/conta_bancaria_model.dart';
import 'package:task_manager_flutter/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/utils.dart';

class ContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaBancariaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<ContaBancaria>(
        title: "Gerenciamento de Contas Bancárias",
        fetchEndpoint: ApiLinks.contasBancarias,
        createEndpoint: ApiLinks.createContaBancaria,
        updateEndpoint: ApiLinks.updateContaBancaria(":id"),
        deleteEndpoint: ApiLinks.deleteContaBancaria(":id"),
        dynamicAdditionalFormData: (item) => {
          'empresaId': pegarEmpresaLogada(),
          'parceiroId': pegarParceiroLogada(),
        },
        fieldConfigs: ContaBancaria.fieldConfigs,
        idFieldName: 'id',
        useUserBannerAppBar: true,
        enableSearch: true,
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        hasPermission: hasPermission,
        fromJson: (json) =>
            ContaBancaria.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        storageKey: 'contas_bancarias_grid',
        customActions: () => [
          CustomAction<ContaBancaria>(
            icon: Icons.toggle_on,
            label: 'Ativar / Desativar',
            onPressed: (context, item) async {
              final caller = ContaBancariaCaller();
              _showLoadingDialog(context, "Atualizando status...");
              final sucesso = await caller.ativarConta(item.id!, !(item.ativo));
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                sucesso
                    ? _showSuccessDialog(context, "Status atualizado!")
                    : _showSnack(context, "Erro ao atualizar status.");
              }
            },
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.swap_horiz,
            label: 'Transferir Saldo',
            onPressed: (context, item) =>
                _showTransferDialog(context, item, ContaBancariaCaller()),
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.picture_as_pdf,
            label: 'Extrato PDF',
            onPressed: (context, item) =>
                _showExtratoDialog(context, item, ContaBancariaCaller()),
          ),
          CustomAction<ContaBancaria>(
            icon: Icons.assessment,
            label: 'Extrato Consolidado',
            onPressed: (context, item) =>
                _showExtratoConsolidado(context, item),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(
      BuildContext context, ContaBancaria conta, ContaBancariaCaller caller) {
    final valorController = TextEditingController();
    final historicoController = TextEditingController();
    int? contaDestinoId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Transferir Saldo"),
        content: FutureBuilder(
          future: ContaBancariaCaller.loadContas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final contas = snapshot.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  items: contas
                      .where((c) => c['value'] != conta.id)
                      .map((c) => DropdownMenuItem<int>(
                            value: c['value'],
                            child: Text(c['label']),
                          ))
                      .toList(),
                  decoration: const InputDecoration(labelText: "Conta destino"),
                  onChanged: (v) => contaDestinoId = v,
                ),
                TextField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Valor"),
                ),
                TextField(
                  controller: historicoController,
                  decoration:
                      const InputDecoration(labelText: "Histórico (opcional)"),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (contaDestinoId == null || valorController.text.isEmpty) {
                _showSnack(context, "Preencha todos os campos obrigatórios.");
                return;
              }
              _showLoadingDialog(context, "Transferindo...");
              final sucesso = await caller.transferirSaldo(
                contaOrigemId: conta.id!,
                contaDestinoId: contaDestinoId!,
                valor: double.parse(valorController.text),
                empresaId: conta.empresa.id!,
                parceiroId: conta.parceiro,
                historico: historicoController.text,
              );
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) {
                sucesso
                    ? _showSuccessDialog(context, "Transferência concluída!")
                    : _showSnack(context, "Erro ao transferir.");
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }

  void _showExtratoDialog(
      BuildContext context, ContaBancaria conta, ContaBancariaCaller caller) {
    final deController = TextEditingController();
    final ateController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Gerar Extrato PDF"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deController,
              decoration: const InputDecoration(labelText: "Data inicial"),
            ),
            TextField(
              controller: ateController,
              decoration: const InputDecoration(labelText: "Data final"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final de = deController.text;
              final ate = ateController.text;
              if (de.isEmpty || ate.isEmpty) {
                _showSnack(context, "Informe as duas datas.");
                return;
              }
              _showLoadingDialog(context, "Gerando PDF...");
              final pdf = await caller.gerarExtratoPdf(
                contaId: conta.id!,
                empresaId: conta.empresa.id!,
                parceiroId: conta.parceiro,
                de: de,
                ate: ate,
              );
              if (context.mounted) Navigator.pop(context);
              if (pdf != null && context.mounted) {
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/extrato_${conta.id}.pdf');
                await file.writeAsBytes(pdf);
                final uri = Uri.file(file.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) _showSuccessDialog(context, "PDF gerado com sucesso!");
              } else if (context.mounted) {
                _showSnack(context, "Erro ao gerar PDF.");
              }
            },
            child: const Text("Gerar PDF"),
          )
        ],
      ),
    );
  }

  void _showExtratoConsolidado(BuildContext context, ContaBancaria conta) {
    final deController = TextEditingController();
    final ateController = TextEditingController();
    final caller = ContaBancariaCaller();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Extrato Consolidado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: deController,
                decoration: const InputDecoration(labelText: "Data inicial")),
            TextField(
                controller: ateController,
                decoration: const InputDecoration(labelText: "Data final")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final de = deController.text;
              final ate = ateController.text;
              if (de.isEmpty || ate.isEmpty) {
                _showSnack(context, "Informe as duas datas.");
                return;
              }
              _showLoadingDialog(context, "Gerando consolidado...");
              // Usa o mesmo endpoint de extrato PDF para consolidado
              final pdf = await ContaBancariaCaller().gerarExtratoPdf(
                contaId: conta.id!,
                empresaId: conta.empresa.id!,
                parceiroId: conta.parceiro,
                de: de,
                ate: ate,
              );
              if (context.mounted) Navigator.pop(context);
              if (pdf != null && context.mounted) {
                final dir = await getTemporaryDirectory();
                final file =
                    File('${dir.path}/extrato_consolidado_${conta.id}.pdf');
                await file.writeAsBytes(pdf);
                final uri = Uri.file(file.path);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) _showSuccessDialog(context, "Consolidado gerado!");
              } else if (context.mounted) {
                _showSnack(context, "Erro ao gerar consolidado.");
              }
            },
            child: const Text("Gerar Consolidado"),
          )
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showLoadingDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(msg),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(fontSize: 16)),
          ]),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }
}
