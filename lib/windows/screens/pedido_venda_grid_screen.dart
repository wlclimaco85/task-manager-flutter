import 'package:flutter/material.dart';
import '../../../models/pedido_venda_model.dart';
import '../../../services/pedido_venda_service.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../constants/custom_colors.dart';
import './details/pedido_venda_detail_screen.dart';
import '../../../windows/dialogs/pedido_venda_historico_dialog.dart';
import '../../../windows/dialogs/faturar_dialog.dart';
import '../../utils/grid_texts.dart';
import '../../../widgets/gated_button.dart';

class WindowsPedidoVendaGridScreen extends StatefulWidget {
  const WindowsPedidoVendaGridScreen({super.key});

  @override
  State<WindowsPedidoVendaGridScreen> createState() =>
      _WindowsPedidoVendaGridScreenState();
}

class _WindowsPedidoVendaGridScreenState
    extends State<WindowsPedidoVendaGridScreen> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _isLoading = true;

  String _statusFilter = 'Todos';
  String _clienteFilter = '';
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final _statusOptions = [
    'Todos',
    'RASCUNHO',
    'APROVADO',
    'REJEITADO',
    'FATURADO_PARCIAL',
    'FATURADO_TOTAL',
    'CANCELADO'
  ];
  final _clienteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await PedidoVendaService.fetchAll(
      status: _statusFilter != 'Todos' ? _statusFilter : null,
      cliente: _clienteFilter.isNotEmpty ? _clienteFilter : null,
      dataInicio: _dataInicio?.toIso8601String().substring(0, 10),
      dataFim: _dataFim?.toIso8601String().substring(0, 10),
    );
    if (mounted) setState(() { _pedidos = data; _isLoading = false; });
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) _dataInicio = picked;
        else _dataFim = picked;
      });
    }
  }

  void _openForm(Map<String, dynamic>? item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PedidoVendaDetailScreen(item: item ?? {})),
    ).then((_) => _load());
  }

  void _showHistorico(List<PedidoVendaHistorico> historico) {
    showDialog(
      context: context,
      builder: (_) => PedidoVendaHistoricoDialog(historico: historico),
    );
  }

  void _showFaturarParcial(Map<String, dynamic> pedido) {
    final id = pedido['id'] as int?;
    final itensRaw = pedido['itens'];
    List<Map<String, dynamic>> itens = [];
    if (itensRaw is List) {
      itens = itensRaw.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (id == null) return;
    showDialog(
      context: context,
      builder: (_) => FaturarDialog(pedidoId: id, itens: itens, onSaved: _load),
    );
  }

  Future<void> _criarDeOrcamento() async {
    final orcamentos = await _fetchOrcamentosAprovados();
    if (!mounted) return;
    if (orcamentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(GridTexts.noApprovedBudgetAvailable), backgroundColor: Colors.orange),
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _OrcamentoPickerDialog(orcamentos: orcamentos),
    );
    if (selected == null) return;
    final orcamentoId = selected['id'] as int?;
    if (orcamentoId == null) return;
    final success = await PedidoVendaService.criarDeOrcamento(orcamentoId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? GridTexts.orderCreatedFromBudgetSuccess
          : GridTexts.orderCreateError),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) _load();
  }

  Future<List<Map<String, dynamic>>> _fetchOrcamentosAprovados() async {
    try {
      final response = await NetworkCaller().getRequest('${ApiLinks.orcamentos}?status=APROVADO');
      if (response.isSuccess && response.body != null) {
        final data = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _confirmAction(String title, String msg, Future<bool> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(GridTexts.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? GridTexts.completedAction(title)
          : GridTexts.actionFailure(title)),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) _load();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'RASCUNHO': return Colors.grey;
      case 'APROVADO': return Colors.green;
      case 'REJEITADO': return Colors.red;
      case 'FATURADO_PARCIAL': return Colors.orange;
      case 'FATURADO_TOTAL': return Colors.blue;
      case 'CANCELADO': return Colors.brown;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _criarDeOrcamento,
                icon: const Icon(Icons.transform, size: 18),
                label: const Text(GridTexts.createFromBudget),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(GridTexts.newOrder),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildTable()),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(GridTexts.statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          SizedBox(
            width: 180,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              isDense: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              controller: _clienteCtrl,
              decoration: const InputDecoration(
                hintText: GridTexts.searchCustomerHint,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _clienteFilter = v,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _pickDate(isInicio: true),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_dataInicio != null ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}' : 'Início', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const Text(GridTexts.until, style: TextStyle(fontSize: 13)),
          InkWell(
            onTap: () => _pickDate(isInicio: false),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_dataFim != null ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}' : 'Fim', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.search, size: 18),
              label: const Text(GridTexts.filter, style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _statusFilter = 'Todos';
                  _clienteFilter = '';
                  _clienteCtrl.clear();
                  _dataInicio = null;
                  _dataFim = null;
                });
                _load();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text(GridTexts.clear, style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pedidos.isEmpty) {
      return const Center(child: Text(GridTexts.noSalesOrderFound));
    }
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text(GridTexts.number, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.customerColumn, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.issueDateLabel, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.totalLabel, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.status, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.source, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.actions, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _pedidos.map((o) {
          final id = o['id'] as int?;
          final status = o['status']?.toString() ?? 'RASCUNHO';
          final total = (o['totalGeral'] as num?)?.toDouble() ?? 0;
          final origem = o['origem']?.toString() ?? (o['orcamentoId'] != null
              ? GridTexts.budgetOrigin
              : GridTexts.directOrigin);
          final historicoRaw = o['historico'];
          List<PedidoVendaHistorico> historico = [];
          if (historicoRaw is List) {
            historico = historicoRaw.map((h) => PedidoVendaHistorico.fromJson(Map<String, dynamic>.from(h))).toList();
          }
          return DataRow(cells: [
            DataCell(Text(o['numero']?.toString() ?? '#${id ?? 0}')),
            DataCell(Text(o['clienteNome']?.toString() ?? '-')),
            DataCell(Text(_formatDate(o['dataEmissao']?.toString()))),
            DataCell(Text(GridTexts.currencyValueRaw(total))),
            DataCell(Chip(
              label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: _statusColor(status),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
            DataCell(Text(origem)),
            DataCell(_buildActions(id, status, historico, o)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildActions(int? id, String status, List<PedidoVendaHistorico> historico, Map<String, dynamic> pedido) {
    if (id == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(Icons.visibility, GridTexts.view, GridColors.info, () => _openForm(_pedidos.firstWhere((o) => o['id'] == id))),
        GatedButton(
          enabled: status == 'RASCUNHO',
          child: _actionIcon(Icons.edit, GridTexts.edit, GridColors.secondary, () => _openForm(_pedidos.firstWhere((o) => o['id'] == id))),
        ),
        GatedButton(
          enabled: status == 'RASCUNHO',
          child: _actionIcon(Icons.check_circle, GridTexts.approve, Colors.green, () => _confirmAction(
            GridTexts.approveOrderTitle, GridTexts.approveOrderQuestion, () => PedidoVendaService.aprovar(id))),
        ),
        GatedButton(
          enabled: status == 'RASCUNHO',
          child: _actionIcon(Icons.cancel, GridTexts.reject, Colors.red, () => _confirmAction(
            GridTexts.rejectOrderTitle, GridTexts.rejectOrderQuestion, () => PedidoVendaService.rejeitar(id))),
        ),
        GatedButton(
          enabled: status == 'APROVADO',
          child: _actionIcon(Icons.payment, GridTexts.partialBilling, Colors.orange, () => _showFaturarParcial(pedido)),
        ),
        GatedButton(
          enabled: status == 'APROVADO',
          child: _actionIcon(Icons.done_all, GridTexts.totalBilling, Colors.blue, () => _confirmAction(
            GridTexts.totalBilling, GridTexts.totalBillingQuestion, () => PedidoVendaService.faturarTotal(id))),
        ),
        GatedButton(
          enabled: status == 'FATURADO_PARCIAL',
          child: _actionIcon(Icons.done_all, GridTexts.totalBilling, Colors.blue, () => _confirmAction(
            GridTexts.totalBilling, GridTexts.totalBillingQuestion, () => PedidoVendaService.faturarTotal(id))),
        ),
        _actionIcon(Icons.block, GridTexts.cancel, Colors.brown, () => _confirmAction(
          GridTexts.cancelOrderTitle, GridTexts.cancelOrderQuestion, () => PedidoVendaService.cancelar(id))),
        _actionIcon(Icons.history, GridTexts.viewHistory, Colors.brown, () => _showHistorico(historico)),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _OrcamentoPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> orcamentos;

  const _OrcamentoPickerDialog({required this.orcamentos});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          children: [
            AppBar(
              title: const Text(GridTexts.selectBudget),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orcamentos.length,
                itemBuilder: (_, i) {
                  final o = orcamentos[i];
                  final id = o['id'] as int?;
                  final label = GridTexts.budgetPickerLabel(
                    o['numero'],
                    o['clienteNome'],
                    (o['totalGeral'] as num?)?.toDouble() ?? 0,
                  );
                  return ListTile(
                    title: Text(label),
                    onTap: () => Navigator.pop(context, o),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
