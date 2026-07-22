import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Tela de detalhes de uma NFe com informações expandíveis
class NfeDetailScreen extends StatefulWidget {
  final int nfeId;

  const NfeDetailScreen({
    Key? key,
    required this.nfeId,
  }) : super(key: key);

  @override
  State<NfeDetailScreen> createState() => _NfeDetailScreenState();
}

class _NfeDetailScreenState extends State<NfeDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega detalhes da NFe ao abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<NfeNotifier>();
      notifier.obterNfe(widget.nfeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da NFe'),
        elevation: 0,
      ),
      body: Consumer<NfeNotifier>(
        builder: (context, notifier, child) {
          final state = notifier.state;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.errorMessage ?? 'Erro desconhecido'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            );
          }

          final nfe = state.selected;
          if (nfe == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('NFe não encontrada'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isMobile
                  ? _buildMobileLayout(context, nfe)
                  : _buildWebLayout(context, nfe),
            ),
          );
        },
      ),
    );
  }

  /// Layout para mobile (stack vertical)
  Widget _buildMobileLayout(BuildContext context, NfeModel nfe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderCard(context, nfe),
        const SizedBox(height: 16),
        _buildInfoCard(context, nfe),
        const SizedBox(height: 16),
        _buildItensExpandable(context, nfe),
        const SizedBox(height: 16),
        _buildImpostosExpandable(context, nfe),
        const SizedBox(height: 16),
        _buildActionButtons(context, nfe),
      ],
    );
  }

  /// Layout para web (2 colunas)
  Widget _buildWebLayout(BuildContext context, NfeModel nfe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeaderCard(context, nfe),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildInfoCard(context, nfe),
                  const SizedBox(height: 16),
                  _buildImpostosExpandable(context, nfe),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _buildItensExpandable(context, nfe),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, nfe),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card com informações principais
  Widget _buildHeaderCard(BuildContext context, NfeModel nfe) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFe ${nfe.numeroFormatado}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nfe.ambienteLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: nfe.isProducao ? Colors.red : Colors.orange,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(nfe.statusNfe),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    nfe.statusNfe.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emitente'),
                    Text(nfe.cnpjEmitente),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UF'),
                    Text(nfe.uf),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data'),
                    Text(nfe.dataHora.toString().split(' ')[0]),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card com informações gerais
  Widget _buildInfoCard(BuildContext context, NfeModel nfe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildInfoRow('Protocolo', nfe.protocolo ?? 'Não emitido'),
            _buildInfoRow('Tomador', nfe.tomador.razaoSocial),
            _buildInfoRow('Total', 'R\$ ${nfe.valores.total.toStringAsFixed(2)}'),
            _buildInfoRow('Emissão', nfe.dataHora.toString()),
            if (nfe.atualizadoEm != null) _buildInfoRow('Atualização', nfe.atualizadoEm.toString()),
          ],
        ),
      ),
    );
  }

  /// Expandable de itens
  Widget _buildItensExpandable(BuildContext context, NfeModel nfe) {
    return Card(
      child: ExpansionTile(
        title: const Text('Itens'),
        initiallyExpanded: true,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('NCM')),
                DataColumn(label: Text('CFOP')),
                DataColumn(label: Text('Descrição')),
                DataColumn(label: Text('Qtd')),
                DataColumn(label: Text('VlUnit')),
                DataColumn(label: Text('Total')),
              ],
              rows: nfe.itens.map<DataRow>((item) {
                return DataRow(cells: [
                  DataCell(Text(item.ncm ?? '-')),
                  DataCell(Text(item.cfop ?? '-')),
                  DataCell(Text(item.descricao)),
                  DataCell(Text(item.quantidade.toString())),
                  DataCell(Text('R\$ ${item.precoUnitario.toStringAsFixed(2)}')),
                  DataCell(Text('R\$ ${item.precoTotal.toStringAsFixed(2)}')),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Expandable de impostos
  Widget _buildImpostosExpandable(BuildContext context, NfeModel nfe) {
    return Card(
      child: ExpansionTile(
        title: const Text('Impostos'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ICMS', 'R\$ ${nfe.valores.totalIcms.toStringAsFixed(2)}'),
                _buildInfoRow('PIS', 'R\$ ${nfe.valores.totalPis.toStringAsFixed(2)}'),
                _buildInfoRow('COFINS', 'R\$ ${nfe.valores.totalCofins.toStringAsFixed(2)}'),
                const Divider(),
                _buildInfoRow('Subtotal', 'R\$ ${nfe.valores.subtotal.toStringAsFixed(2)}'),
                _buildInfoRow('Desconto', 'R\$ ${nfe.valores.desconto.toStringAsFixed(2)}'),
                _buildInfoRow('Total', 'R\$ ${nfe.valores.total.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botões de ação (Emitir, Cancelar, etc)
  Widget _buildActionButtons(BuildContext context, NfeModel nfe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nfe.statusNfe == NfeStatus.pendente)
              ElevatedButton.icon(
                onPressed: () {
                  L.d('[NfeDetailScreen] Emitindo NFe ${nfe.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emissão em implementação')),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Emitir'),
              ),
            if (nfe.statusNfe == NfeStatus.autorizada)
              ElevatedButton.icon(
                onPressed: () {
                  L.d('[NfeDetailScreen] Cancelando NFe ${nfe.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cancelamento em implementação')),
                  );
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            const SizedBox(height: 8),
            if (nfe.canDownloadPdf)
              OutlinedButton.icon(
                onPressed: () {
                  L.d('[NfeDetailScreen] Download PDF NFe ${nfe.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download em implementação')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
              ),
            if (nfe.canViewXml)
              OutlinedButton.icon(
                onPressed: () {
                  L.d('[NfeDetailScreen] Visualizando XML NFe ${nfe.id}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('XML viewer em implementação')),
                  );
                },
                icon: const Icon(Icons.code),
                label: const Text('Visualizar XML'),
              ),
          ],
        ),
      ),
    );
  }

  /// Helper: linha de informação
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  /// Helper: retorna cor baseado no status
  Color _getStatusColor(NfeStatus status) {
    switch (status) {
      case NfeStatus.autorizada:
        return Colors.green;
      case NfeStatus.rejeitada:
        return Colors.red;
      case NfeStatus.cancelada:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }
}
