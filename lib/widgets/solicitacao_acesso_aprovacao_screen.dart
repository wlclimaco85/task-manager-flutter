import 'package:flutter/material.dart';

import '../services/solicitacao_acesso_caller.dart';
import '../utils/grid_colors.dart';

class SolicitacaoAcessoAprovacaoScreen extends StatefulWidget {
  const SolicitacaoAcessoAprovacaoScreen({super.key});

  @override
  State<SolicitacaoAcessoAprovacaoScreen> createState() =>
      _SolicitacaoAcessoAprovacaoScreenState();
}

class _SolicitacaoAcessoAprovacaoScreenState
    extends State<SolicitacaoAcessoAprovacaoScreen> {
  bool _carregando = true;
  List<SolicitacaoAcessoItem> _itens = [];
  final Set<int> _processando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await SolicitacaoAcessoCaller.listarPendentes();
    if (!mounted) return;
    setState(() {
      _itens = lista;
      _carregando = false;
    });
  }

  Future<void> _confirmarAprovar(SolicitacaoAcessoItem item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: GridColors.success),
            const SizedBox(width: 8),
            const Text('Aprovar acesso'),
          ],
        ),
        content: Text(
            'Aprovar acesso de ${item.nome}? Um novo login será criado com o email ${item.email}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GridColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _executar(item, aprovar: true);
  }

  Future<void> _confirmarRejeitar(SolicitacaoAcessoItem item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.cancel, color: GridColors.error),
            const SizedBox(width: 8),
            const Text('Rejeitar solicitação'),
          ],
        ),
        content: Text('Rejeitar a solicitação de acesso de ${item.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: GridColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _executar(item, aprovar: false);
  }

  Future<void> _executar(SolicitacaoAcessoItem item,
      {required bool aprovar}) async {
    setState(() => _processando.add(item.id));
    final erro = aprovar
        ? await SolicitacaoAcessoCaller.aprovar(item.id)
        : await SolicitacaoAcessoCaller.rejeitar(item.id);
    if (!mounted) return;

    setState(() {
      _processando.remove(item.id);
      if (erro == null) {
        _itens.removeWhere((i) => i.id == item.id);
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    if (erro != null) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: GridColors.error,
        content: Text(erro),
      ));
      if (erro.contains('já foi processada')) {
        _carregar();
      }
    } else {
      messenger.showSnackBar(SnackBar(
        backgroundColor: aprovar ? GridColors.success : GridColors.neutral,
        content: Text(aprovar
            ? 'Acesso aprovado para ${item.nome}.'
            : 'Solicitação rejeitada.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.how_to_reg, color: GridColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Solicitações de Acesso${_itens.isNotEmpty ? ' (${_itens.length})' : ''}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregando ? null : _carregar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? _buildSkeleton()
                  : _itens.isEmpty
                      ? _buildEstadoVazio()
                      : _buildTabela(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 48,
        decoration: BoxDecoration(
          color: GridColors.disabledBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, size: 64, color: GridColors.divider),
          SizedBox(height: 12),
          Text('Nenhuma solicitação pendente',
              style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('Novas solicitações de acesso aparecerão aqui.',
              style: TextStyle(color: GridColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('CPF/CNPJ')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Destino')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _itens.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final processando = _processando.contains(item.id);
          return DataRow(
            color: WidgetStateProperty.all(
              i.isEven ? GridColors.rowEven : GridColors.rowOdd,
            ),
            cells: [
              DataCell(Text(item.nome)),
              DataCell(Text(_mascarar(item.cpfCnpj))),
              DataCell(Text(item.email)),
              DataCell(Text(_formatarData(item.dataCriacao))),
              DataCell(_buildChipDestino(item)),
              DataCell(
                processando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Aprovar',
                            icon: const Icon(Icons.check_circle,
                                color: GridColors.success, size: 20),
                            onPressed: () => _confirmarAprovar(item),
                          ),
                          IconButton(
                            tooltip: 'Rejeitar',
                            icon: const Icon(Icons.cancel,
                                color: GridColors.error, size: 20),
                            onPressed: () => _confirmarRejeitar(item),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChipDestino(SolicitacaoAcessoItem item) {
    final filaEscritorio = item.destinoFilaEscritorio;
    return Chip(
      label: Text(
        filaEscritorio ? 'Fila do escritório' : 'Usuário do CNPJ',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: filaEscritorio
          ? GridColors.warning.withValues(alpha: 0.15)
          : GridColors.secondarySoft,
      side: BorderSide(
        color: filaEscritorio
            ? GridColors.warningDark.withValues(alpha: 0.3)
            : GridColors.secondary.withValues(alpha: 0.3),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  String _mascarar(String doc) {
    final digits = doc.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.***.**${digits.substring(8, 9)}-${digits.substring(9)}';
    }
    if (digits.length == 14) {
      return '${digits.substring(0, 2)}.***.***/****-${digits.substring(12)}';
    }
    return doc;
  }

  String _formatarData(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
