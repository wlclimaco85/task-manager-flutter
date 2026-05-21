import 'package:flutter/material.dart';
import '../../services/baixa_automatica_caller.dart';
import '../../utils/utils.dart';

class BaixaAutomaticaScreen extends StatefulWidget {
  const BaixaAutomaticaScreen({super.key});

  @override
  State<BaixaAutomaticaScreen> createState() => _BaixaAutomaticaScreenState();
}

class _BaixaAutomaticaScreenState extends State<BaixaAutomaticaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Importar
  final _linhasCtrl = TextEditingController();
  String _tipoSelecionado = 'CNAB';
  bool _loadingImport = false;

  // Conferência
  List<Map<String, dynamic>> _pendentes = [];
  bool _loadingPendentes = false;

  // Histórico
  final _contaReceberIdCtrl = TextEditingController();
  List<Map<String, dynamic>> _historico = [];
  bool _loadingHistorico = false;

  static const _tipos = ['CNAB', 'CSV', 'MANUAL'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _carregarPendentes();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _linhasCtrl.dispose();
    _contaReceberIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _importar() async {
    final linhas = _linhasCtrl.text.trim();
    if (linhas.isEmpty) return;
    setState(() => _loadingImport = true);
    try {
      final res = await BaixaAutomaticaCaller.importar(
        linhas: linhas,
        tipo: _tipoSelecionado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: res.isSuccess ? Colors.green : Colors.red,
          content: Text(res.isSuccess
              ? 'Importação realizada com sucesso!'
              : 'Erro (${res.statusCode})'),
        ));
        if (res.isSuccess) {
          _linhasCtrl.clear();
          await _carregarPendentes();
          _tabCtrl.animateTo(1);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro: $e'),
        ));
      }
    }
    if (mounted) setState(() => _loadingImport = false);
  }

  Future<void> _carregarPendentes() async {
    setState(() => _loadingPendentes = true);
    try {
      final res = await BaixaAutomaticaCaller.pendentes();
      if (res.isSuccess && res.body != null) {
        _pendentes = _extrairLista(res.body!);
      } else {
        _pendentes = [];
      }
    } catch (_) {
      _pendentes = [];
    }
    if (mounted) setState(() => _loadingPendentes = false);
  }

  Future<void> _carregarHistorico() async {
    final id = _contaReceberIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _loadingHistorico = true);
    try {
      final res =
          await BaixaAutomaticaCaller.historico(contaReceberId: id);
      if (res.isSuccess && res.body != null) {
        _historico = _extrairLista(res.body!);
      } else {
        _historico = [];
      }
    } catch (_) {
      _historico = [];
    }
    if (mounted) setState(() => _loadingHistorico = false);
  }

  List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.where((v) => v is List);
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }

  Future<void> _confirmarAcao(
      Map<String, dynamic> item, String acao) async {
    final acaoLabel = acao == 'CONFIRMAR' ? 'Confirmar' : 'Rejeitar';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$acaoLabel Baixa'),
        content: Text(
            '${acaoLabel} a baixa da conta "${item['conta'] ?? item['descricao'] ?? ''}" Valor: ${_formatValor(item['valor'])}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: acao == 'CONFIRMAR' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(acaoLabel),
          ),
        ],
      ),
    );

    if (result != true) return;

    final id = item['id'];
    setState(() => _loadingPendentes = true);
    try {
      final res = await BaixaAutomaticaCaller.conferir(id: id, acao: acao);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: res.isSuccess ? Colors.green : Colors.red,
          content: Text(res.isSuccess
              ? 'Baixa $acaoLabel com sucesso!'
              : 'Erro (${res.statusCode})'),
        ));
        if (res.isSuccess) await _carregarPendentes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro: $e'),
        ));
      }
    }
    if (mounted) setState(() => _loadingPendentes = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baixa Automática de Recebíveis'),
        bottom: TabBar(
          controller: _tabCtrl,
          onTap: (i) {
            if (i == 1) _carregarPendentes();
          },
          tabs: const [
            Tab(text: 'Importar'),
            Tab(text: 'Conferência'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildImportarTab(),
          _buildConferenciaTab(),
          _buildHistoricoTab(),
        ],
      ),
    );
  }

  Widget _buildImportarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Colar linhas CNAB',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _linhasCtrl,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Cole as linhas do CNAB aqui...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _tipoSelecionado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _tipos
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _tipoSelecionado = v);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (_loadingImport || _linhasCtrl.text.trim().isEmpty)
                ? null
                : _importar,
            icon: _loadingImport
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.upload, size: 18),
            label: Text(_loadingImport ? 'Importando...' : 'Importar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenciaTab() {
    if (_loadingPendentes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pendentes.isEmpty) {
      return const Center(child: Text('Nenhuma pendência.'));
    }
    return RefreshIndicator(
      onRefresh: _carregarPendentes,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Conta')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Juros/Multa/Desc.')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _pendentes.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['conta']?.toString() ??
                  item['descricao']?.toString() ??
                  '')),
              DataCell(Text(_formatValor(item['valor']))),
              DataCell(
                  Text(_formatData(item['data'] ?? item['createdAt']))),
              DataCell(Text(_formatValor(item['jurosMulta'] ??
                  item['juros'] ??
                  item['desconto']))),
              DataCell(Text(item['status']?.toString() ?? 'PENDENTE')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    tooltip: 'Confirmar',
                    onPressed: () =>
                        _confirmarAcao(item, 'CONFIRMAR'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.cancel,
                        color: Colors.red, size: 20),
                    tooltip: 'Rejeitar',
                    onPressed: () =>
                        _confirmarAcao(item, 'REJEITAR'),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _contaReceberIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conta a Receber ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadingHistorico ? null : _carregarHistorico,
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Buscar'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildHistoricoGrid()),
      ],
    );
  }

  Widget _buildHistoricoGrid() {
    if (_loadingHistorico) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historico.isEmpty) {
      return const Center(child: Text('Nenhum histórico encontrado.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Conta')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Juros/Multa')),
        ],
        rows: _historico.map((h) {
          return DataRow(cells: [
            DataCell(Text(h['conta']?.toString() ??
                h['descricao']?.toString() ?? '')),
            DataCell(Text(_formatValor(h['valor']))),
            DataCell(
                Text(_formatData(h['data'] ?? h['createdAt']))),
            DataCell(Text(h['status']?.toString() ?? '')),
            DataCell(Text(_formatValor(
                h['jurosMulta'] ?? h['juros'] ?? h['desconto']))),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatValor(dynamic val) {
    if (val == null) return '';
    final num v = (val is num) ? val : double.tryParse(val.toString()) ?? 0;
    return 'R\$ ${v.toStringAsFixed(2)}';
  }

  String _formatData(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return val.toString();
    }
  }
}
