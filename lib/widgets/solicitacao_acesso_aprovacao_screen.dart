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
  bool _erroCarregamento = false;
  List<SolicitacaoAcessoItem> _itens = [];
  final Set<int> _processando = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erroCarregamento = false;
    });
    final lista = await SolicitacaoAcessoCaller.listarPendentes();
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (lista == null) {
        _erroCarregamento = true;
      } else {
        _itens = lista;
      }
    });
  }

  Future<void> _confirmarAprovar(SolicitacaoAcessoItem item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => _AprovacaoWizardDialog(item: item),
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
    final resultado = aprovar
        ? await SolicitacaoAcessoCaller.aprovar(item.id)
        : await SolicitacaoAcessoCaller.rejeitar(item.id);
    if (!mounted) return;

    setState(() {
      _processando.remove(item.id);
      if (resultado.sucesso) {
        _itens.removeWhere((i) => i.id == item.id);
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    if (!resultado.sucesso) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: GridColors.error,
        content: Text(resultado.mensagemErro ??
            'Erro ao processar a solicitação. Tente novamente.'),
      ));
      if (resultado.conflito) {
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
                  : _erroCarregamento
                      ? _buildEstadoErro()
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

  Widget _buildEstadoErro() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: GridColors.error),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar as solicitações',
              style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Verifique sua conexão e tente novamente.',
              style: TextStyle(color: GridColors.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tentar novamente'),
          ),
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
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Text(
          item.destinoNome,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
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
    // Documento com tamanho inesperado: nunca exibe sem mascara (PII).
    return digits.isEmpty ? '—' : '***';
  }

  String _formatarData(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AprovacaoWizardDialog extends StatefulWidget {
  const _AprovacaoWizardDialog({required this.item});

  final SolicitacaoAcessoItem item;

  @override
  State<_AprovacaoWizardDialog> createState() => _AprovacaoWizardDialogState();
}

class _AprovacaoWizardDialogState extends State<_AprovacaoWizardDialog> {
  int _etapa = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final confirmacao = _etapa == 1;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      title: Row(
        children: [
          const Icon(Icons.how_to_reg, color: GridColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
                confirmacao ? 'Confirmar aprovacao' : 'Revisar solicitacao'),
          ),
          Text(
            '${_etapa + 1}/2',
            style: const TextStyle(
              fontSize: 12,
              color: GridColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_etapa + 1) / 2,
              color: GridColors.success,
              backgroundColor: GridColors.disabledBackground,
              minHeight: 3,
            ),
            const SizedBox(height: 20),
            if (!confirmacao) ...[
              _WizardInfo(label: 'Solicitante', value: item.nome),
              _WizardInfo(label: 'Email', value: item.email),
              _WizardInfo(label: 'Destino', value: item.destinoNome),
              const _WizardInfo(label: 'Perfil de acesso', value: 'CLIENTE'),
            ] else ...[
              const Text(
                'O login sera criado com os dados abaixo:',
                style: TextStyle(color: GridColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _WizardInfo(label: 'Cliente', value: item.nome),
              _WizardInfo(label: 'Destino', value: item.destinoNome),
              const _WizardInfo(label: 'Role fixa', value: 'CLIENTE'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        if (confirmacao)
          OutlinedButton.icon(
            onPressed: () => setState(() => _etapa = 0),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Voltar'),
          ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: GridColors.success),
          onPressed: confirmacao
              ? () => Navigator.pop(context, true)
              : () => setState(() => _etapa = 1),
          icon: Icon(confirmacao ? Icons.check : Icons.arrow_forward, size: 18),
          label: Text(confirmacao ? 'Aprovar cliente' : 'Continuar'),
        ),
      ],
    );
  }
}

class _WizardInfo extends StatelessWidget {
  const _WizardInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: GridColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
