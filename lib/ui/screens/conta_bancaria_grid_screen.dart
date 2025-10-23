import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_manager_flutter/data/customization/generic_grid_card.dart';
import 'package:task_manager_flutter/data/models/conta_bancaria_model.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/utils.dart';

class ContaBancariaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const ContaBancariaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GenericMobileGridScreen<ContaBancaria>(
        title: "Gerenciamento de Contas Bancárias",
        fetchEndpoint: ApiLinks.allContasBancarias,
        createEndpoint: ApiLinks.createContaBancaria,
        updateEndpoint: ApiLinks.updateContaBancaria(":id"),
        deleteEndpoint: ApiLinks.deleteContaBancaria(":id"),
        dynamicAdditionalFormData: (item) {
          return {
            'empresa': {'id': pegarEmpresaLogada()},
          };
        },
        useUserBannerAppBar: true,
        fromJson: (json) =>
            ContaBancaria.fromJson(Map<String, dynamic>.from(json)),
        toJson: (obj) => obj.toJson(),
        hasPermission: hasPermission,
        fieldConfigs: ContaBancaria.fieldConfigs,
        idFieldName: 'id',
        paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10,
          availableRowsPerPage: [10, 25, 50],
        ),
        enableSearch: true,
        storageKey: 'contas_bancarias_grid',
        customActions: () => [
          // 🔁 Ativar/Desativar
          CustomAction<ContaBancaria>(
            icon: Icons.toggle_on,
            label: 'Ativar/Desativar',
            onPressed: (context, item) async {
              final caller = ContaBancariaCaller();
              final sucesso = await caller.ativarConta(item.id!, !(item.ativo));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sucesso
                        ? 'Status da conta atualizado!'
                        : 'Falha ao atualizar status.'),
                  ),
                );
              }
            },
          ),

          // 🔄 Transferir saldo
          CustomAction<ContaBancaria>(
            icon: Icons.swap_horiz,
            label: 'Transferir Saldo',
            onPressed: (context, item) {
              _showTransferDialog(context, item);
            },
          ),

          // 📄 Gerar extrato PDF
          CustomAction<ContaBancaria>(
            icon: Icons.picture_as_pdf,
            label: 'Gerar Extrato PDF',
            onPressed: (context, item) {
              _showExtratoDialog(context, item);
            },
          ),
        ],
      ),
    );
  }

  // 🔁 Diálogo de transferência
  void _showTransferDialog(BuildContext context, ContaBancaria contaOrigem) {
    final valorController = TextEditingController();
    final historicoController = TextEditingController();
    int? contaDestinoId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transferir Saldo'),
        content: FutureBuilder<List<Map<String, dynamic>>>(
          future: ContaBancariaCaller.loadContas(), // ✅ agora puxa contas reais
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Erro ao carregar contas: ${snapshot.error}');
            }
            final contas = snapshot.data ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration:
                      const InputDecoration(labelText: 'Conta de destino'),
                  items: contas
                      .where((c) => c['value'] != contaOrigem.id)
                      .map((c) => DropdownMenuItem<int>(
                            value: c['value'],
                            child: Text(c['label']),
                          ))
                      .toList(),
                  onChanged: (v) => contaDestinoId = v,
                ),
                TextField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Valor da transferência'),
                ),
                TextField(
                  controller: historicoController,
                  decoration:
                      const InputDecoration(labelText: 'Histórico (opcional)'),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contaDestinoId == null || valorController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Preencha todos os campos obrigatórios.')),
                );
                return;
              }

              final caller = ContaBancariaCaller();
              final sucesso = await caller.transferirSaldo(
                contaOrigemId: contaOrigem.id!,
                contaDestinoId: contaDestinoId!,
                valor: double.parse(valorController.text),
                empresaId: contaOrigem.empresa.id!,
                parceiroId: contaOrigem.parceiro?.id,
                historico: historicoController.text,
              );

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sucesso
                        ? 'Transferência realizada com sucesso!'
                        : 'Erro ao transferir saldo.'),
                  ),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // 📄 Diálogo de extrato PDF
  void _showExtratoDialog(BuildContext context, ContaBancaria conta) {
    final deController = TextEditingController();
    final ateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar Extrato PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deController,
              decoration:
                  const InputDecoration(labelText: 'Data inicial (AAAA-MM-DD)'),
            ),
            TextField(
              controller: ateController,
              decoration:
                  const InputDecoration(labelText: 'Data final (AAAA-MM-DD)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final de = deController.text.trim();
              final ate = ateController.text.trim();

              if (de.isEmpty || ate.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Preencha as datas de início e fim.')),
                );
                return;
              }

              final caller = ContaBancariaCaller();
              final pdfBytes = await caller.gerarExtratoPdf(
                contaId: conta.id!,
                empresaId: conta.empresa.id!,
                parceiroId: conta.parceiro?.id,
                de: de,
                ate: ate,
              );

              if (pdfBytes != null) {
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/extrato_${conta.id}.pdf');
                await file.writeAsBytes(pdfBytes);
                await OpenFilex.open(file.path);
                if (context.mounted) Navigator.pop(ctx);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erro ao gerar ou abrir o PDF.')),
                  );
                }
              }
            },
            child: const Text('Gerar PDF'),
          ),
        ],
      ),
    );
  }
}
