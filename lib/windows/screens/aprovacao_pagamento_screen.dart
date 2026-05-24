import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';
import '../../services/aprovacao_pagamento_caller.dart';
import '../../utils/utils.dart';
import '../../utils/grid_texts.dart';

class AprovacaoPagamentoScreen extends StatefulWidget {
  const AprovacaoPagamentoScreen({super.key});

  @override
  State<AprovacaoPagamentoScreen> createState() =>
      _AprovacaoPagamentoScreenState();
}

class _AprovacaoPagamentoScreenState extends State<AprovacaoPagamentoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _contaPagarIdCtrl = TextEditingController();

  List<Map<String, dynamic>> _fila = [];
  List<Map<String, dynamic>> _historico = [];
  bool _loadingFila = false;
  bool _loadingHistorico = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _carregarFila();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _contaPagarIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarFila() async {
    setState(() => _loadingFila = true);
    try {
      final empresaId = pegarEmpresaLogada() ?? 0;
      final res =
          await AprovacaoPagamentoCaller.fila(empresaId: empresaId);
      if (res.isSuccess && res.body != null) {
        _fila = _extrairLista(res.body!);
      } else {
        _fila = [];
      }
    } catch (_) {
      _fila = [];
    }
    if (mounted) setState(() => _loadingFila = false);
  }

  Future<void> _carregarHistorico() async {
    final id = _contaPagarIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _loadingHistorico = true);
    try {
      final res =
          await AprovacaoPagamentoCaller.historico(contaPagarId: id);
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
      Map<String, dynamic> item, bool isAprovar) async {
    final justifCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAprovar ? GridTexts.approvePayment : GridTexts.rejectPayment),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(GridTexts.accountLabel((item['conta'] ?? item['descricao'] ?? '').toString())),
            const SizedBox(height: 12),
            TextField(
              controller: justifCtrl,
              decoration: const InputDecoration(
                labelText: GridTexts.justificationRequired,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (justifCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, justifCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAprovar ? GridColors.success : GridColors.error,
              foregroundColor: GridColors.buttonText,
            ),
            child: Text(isAprovar ? 'Aprovar' : 'Reprovar'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final id = item['id'];
    setState(() => _loadingFila = true);
    try {
      final res = isAprovar
          ? await AprovacaoPagamentoCaller.aprovar(
              aprovacaoId: id, justificativa: result)
          : await AprovacaoPagamentoCaller.reprovar(
              aprovacaoId: id, justificativa: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: res.isSuccess ? GridColors.success : GridColors.error,
          content: Text(res.isSuccess
              ? 'Pagamento ${isAprovar ? "aprovado" : "reprovado"} com sucesso!'
              : 'Erro (${res.statusCode})'),
        ));
        if (res.isSuccess) await _carregarFila();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GridColors.error,
          content: Text('Erro: $e'),
        ));
      }
    }
    if (mounted) setState(() => _loadingFila = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovação de Pagamentos'),
        bottom: TabBar(
          controller: _tabCtrl,
          onTap: (i) {
            if (i == 0) _carregarFila();
          },
          tabs: const [
            Tab(text: 'Fila'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFilaTab(),
          _buildHistoricoTab(),
        ],
      ),
    );
  }

  Widget _buildFilaTab() {
    if (_loadingFila) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fila.isEmpty) {
      return const Center(
        child: Text('Nenhuma aprovação pendente.'),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Conta')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Solicitante')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _fila.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['conta']?.toString() ??
                item['descricao']?.toString() ??
                '')),
            DataCell(Text(_formatValor(item['valor']))),
            DataCell(Text(item['solicitante']?.toString() ?? '')),
            DataCell(Text(_formatData(item['data'] ?? item['createdAt']))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: GridColors.success, size: 20),
                  tooltip: 'Aprovar',
                  onPressed: () => _confirmarAcao(item, true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel,
                      color: GridColors.error, size: 20),
                  tooltip: 'Reprovar',
                  onPressed: () => _confirmarAcao(item, false),
                ),
              ],
            )),
          ]);
        }).toList(),
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
                  controller: _contaPagarIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conta a Pagar ID',
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
                label: const Text(GridTexts.search),
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
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Solicitante')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Justificativa')),
        ],
        rows: _historico.map((h) {
          return DataRow(cells: [
            DataCell(Text(h['status']?.toString() ?? '')),
            DataCell(Text(_formatValor(h['valor']))),
            DataCell(Text(h['solicitante']?.toString() ?? '')),
            DataCell(Text(_formatData(h['data'] ?? h['createdAt']))),
            DataCell(Text(h['justificativa']?.toString() ?? '')),
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
