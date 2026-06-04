// lib/web/screens/cobranca_automatica_screen.dart
import 'package:flutter/material.dart';
import '../../services/cobranca_service.dart';
import '../../utils/grid_colors.dart';

/// Screen for automatic cobrança (collection) management.
class CobrancaAutomaticaScreen extends StatefulWidget {
  const CobrancaAutomaticaScreen({super.key});

  @override
  State<CobrancaAutomaticaScreen> createState() => _CobrancaAutomaticaScreenState();
}

class _CobrancaAutomaticaScreenState extends State<CobrancaAutomaticaScreen>
    with SingleTickerProviderStateMixin {
  final _service = CobrancaService();
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _pendentes = [];
  bool _loadingPendentes = false;
  Set<String> _selectedPendentes = {};

  List<Map<String, dynamic>> _historico = [];
  bool _loadingHistorico = false;

  String _statusFilter = 'Todos';
  final _statusOptions = ['Todos', 'ENVIADO', 'AGUARDANDO', 'ERRO', 'CONCLUIDO'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadPendentes();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPendentes() async {
    setState(() => _loadingPendentes = true);
    try {
      _pendentes = await _service.getPendentes();
    } catch (_) {
      _pendentes = [];
    }
    if (mounted) setState(() => _loadingPendentes = false);
  }

  Future<void> _loadHistorico() async {
    setState(() => _loadingHistorico = true);
    try {
      _historico = await _service.getHistorico();
    } catch (_) {
      _historico = [];
    }
    if (mounted) setState(() => _loadingHistorico = false);
  }

  Future<void> _enviarCobranca() async {
    if (_selectedPendentes.isEmpty) return;
    final ids = _selectedPendentes.map((id) => int.tryParse(id) ?? 0).toList();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar Cobrança'),
        content: Text('Enviar cobrança para ${ids.length} conta(s) selecionada(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.secondary, foregroundColor: Colors.white),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loadingPendentes = true);
    try {
      final result = await _service.enviarCobranca(ids);
      if (mounted) {
        final success = result['success'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: success ? GridColors.success : GridColors.error,
          content: Text(result['mensagem'] ?? (success ? 'Cobrança enviada com sucesso!' : 'Erro ao enviar cobrança')),
        ));
        if (success) {
          _selectedPendentes.clear();
          await _loadPendentes();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: GridColors.error, content: Text('Erro: $e')));
      }
    }
    if (mounted) setState(() => _loadingPendentes = false);
  }

  List<Map<String, dynamic>> get _filteredPendentes {
    if (_statusFilter == 'Todos') return _pendentes;
    return _pendentes.where((p) => (p['status']?.toString().toUpperCase() ?? '') == _statusFilter).toList();
  }

  Color _statusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ENVIADO': return GridColors.success;
      case 'AGUARDANDO': return GridColors.warning;
      case 'ERRO': return GridColors.error;
      case 'CONCLUIDO': return GridColors.primary;
      default: return GridColors.textMuted;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toUpperCase()) {
      case 'ENVIADO': return Icons.check_circle;
      case 'AGUARDANDO': return Icons.hourglass_empty;
      case 'ERRO': return Icons.error;
      case 'CONCLUIDO': return Icons.done_all;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(color: GridColors.card, border: Border(bottom: BorderSide(color: GridColors.divider))),
          child: Row(
            children: [
              const Icon(Icons.money_off, color: GridColors.secondary, size: 24),
              const SizedBox(width: 10),
              const Text('Cobrança Automática', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GridColors.textSecondary)),
              const Spacer(),
              if (_selectedPendentes.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _loadingPendentes ? null : _enviarCobranca,
                  icon: const Icon(Icons.send, size: 16),
                  label: Text('Enviar Cobrança (${_selectedPendentes.length})'),
                  style: ElevatedButton.styleFrom(backgroundColor: GridColors.secondary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () { if (_tabCtrl.index == 0) _loadPendentes(); else _loadHistorico(); },
                tooltip: 'Atualizar',
              ),
            ],
          ),
        ),
        Container(
          color: GridColors.card,
          child: TabBar(
            controller: _tabCtrl,
            onTap: (i) { if (i == 1) _loadHistorico(); },
            labelColor: GridColors.secondary,
            unselectedLabelColor: GridColors.textMuted,
            indicatorColor: GridColors.secondary,
            tabs: const [Tab(text: 'Pendentes'), Tab(text: 'Histórico')],
          ),
        ),
        if (_tabCtrl.index == 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: GridColors.filterBackground.withOpacity(0.5),
            child: Row(
              children: [
                const Text('Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  height: 34,
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    isDense: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder()),
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ),
                const Spacer(),
                Text('${_filteredPendentes.length} registro(s)', style: const TextStyle(fontSize: 12, color: GridColors.textMuted)),
              ],
            ),
          ),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [_buildPendentesTab(), _buildHistoricoTab()]),
        ),
      ],
    );
  }

  Widget _buildPendentesTab() {
    if (_loadingPendentes) return const Center(child: CircularProgressIndicator());
    if (_filteredPendentes.isEmpty) return const Center(child: Text('Nenhuma cobrança pendente', style: TextStyle(color: GridColors.textMuted)));

    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
        columns: [
          const DataColumn(label: Text('')),
          const DataColumn(label: Text('Cliente')),
          const DataColumn(label: Text('Descrição')),
          const DataColumn(label: Text('Valor')),
          const DataColumn(label: Text('Vencimento')),
          const DataColumn(label: Text('Status')),
        ],
        rows: _filteredPendentes.map((p) {
          final id = p['id']?.toString() ?? '';
          final selected = _selectedPendentes.contains(id);
          return DataRow(
            selected: selected,
            onSelectChanged: (v) { setState(() { if (v == true) { _selectedPendentes.add(id); } else { _selectedPendentes.remove(id); } }); },
            cells: [
              DataCell(Checkbox(value: selected, onChanged: (v) { setState(() { if (v == true) { _selectedPendentes.add(id); } else { _selectedPendentes.remove(id); } }); })),
              DataCell(Text(p['clienteNome']?.toString() ?? p['parceiro']?.toString() ?? '')),
              DataCell(Text(p['descricao']?.toString() ?? '', overflow: TextOverflow.ellipsis)),
              DataCell(Text('R\$ ${(p['valor'] ?? 0).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(p['dataVencimento']?.toString() ?? '')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _statusColor(p['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(p['status']), size: 14, color: _statusColor(p['status'])),
                      const SizedBox(width: 4),
                      Text(p['status']?.toString() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _statusColor(p['status']))),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_loadingHistorico) return const Center(child: CircularProgressIndicator());
    if (_historico.isEmpty) return const Center(child: Text('Nenhum histórico encontrado', style: TextStyle(color: GridColors.textMuted)));

    return SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Descrição')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Detalhes')),
        ],
        rows: _historico.map((h) {
          return DataRow(cells: [
            DataCell(Text(h['dataEnvio']?.toString() ?? h['createdAt']?.toString() ?? '')),
            DataCell(Text(h['clienteNome']?.toString() ?? h['parceiro']?.toString() ?? '')),
            DataCell(Text(h['descricao']?.toString() ?? '', overflow: TextOverflow.ellipsis)),
            DataCell(Text('R\$ ${(h['valor'] ?? 0).toDouble().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(h['status']).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(h['status']?.toString() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _statusColor(h['status']))),
              ),
            ),
            DataCell(Text(h['mensagem']?.toString() ?? h['detalhes']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: GridColors.textMuted))),
          ]);
        }).toList(),
      ),
    );
  }
}
