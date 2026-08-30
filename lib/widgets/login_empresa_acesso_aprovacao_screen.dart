import 'package:flutter/material.dart';

import '../services/login_empresa_acesso_caller.dart';
import '../utils/grid_colors.dart';

/// Tela basica de aprovacao/rejeicao de solicitacoes de acesso multi-empresa
/// (Task 5, fase 178) — clone estrutural de
/// `SolicitacaoAcessoAprovacaoScreen` (mesmos estados: carregando, vazio,
/// erro, tabela com acoes), trocando a fonte de dados para
/// `LoginEmpresaAcessoCaller`.
class LoginEmpresaAcessoAprovacaoScreen extends StatefulWidget {
  const LoginEmpresaAcessoAprovacaoScreen({super.key});

  @override
  State<LoginEmpresaAcessoAprovacaoScreen> createState() =>
      _LoginEmpresaAcessoAprovacaoScreenState();
}

class _LoginEmpresaAcessoAprovacaoScreenState
    extends State<LoginEmpresaAcessoAprovacaoScreen> {
  bool _carregando = true;
  bool _erroCarregamento = false;
  List<LoginEmpresaAcessoPendenteItem> _itens = [];
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
    final lista = await LoginEmpresaAcessoCaller.listarPendentes();
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

  Future<void> _confirmarAprovar(LoginEmpresaAcessoPendenteItem item) async {
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
            'Aprovar acesso de ${item.loginNome} à empresa ${item.empresaNome}?'),
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

  Future<void> _confirmarRejeitar(LoginEmpresaAcessoPendenteItem item) async {
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
        content: Text(
            'Rejeitar a solicitação de acesso de ${item.loginNome} à empresa ${item.empresaNome}?'),
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

  Future<void> _executar(LoginEmpresaAcessoPendenteItem item,
      {required bool aprovar}) async {
    setState(() => _processando.add(item.id));
    final resultado = aprovar
        ? await LoginEmpresaAcessoCaller.aprovar(item.id)
        : await LoginEmpresaAcessoCaller.rejeitar(item.id);
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
            ? 'Acesso aprovado para ${item.loginNome}.'
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
                  'Aprovação Multi-Empresa${_itens.isNotEmpty ? ' (${_itens.length})' : ''}',
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
          Text('Novas solicitações de acesso a empresa aparecerão aqui.',
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
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Empresa solicitada')),
          DataColumn(label: Text('Data')),
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
              DataCell(Text(item.loginNome)),
              DataCell(Text(item.loginEmail)),
              DataCell(Text(item.empresaNome)),
              DataCell(Text(_formatarData(item.dataCriacao))),
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

  String _formatarData(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
