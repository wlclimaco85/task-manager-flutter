import 'package:flutter/material.dart';

import '../services/nfse_faturar_service.dart';
import '../services/parceiro_faturamento_service.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/grid_colors.dart';
import '../utils/nfse_faturar_utils.dart';
import '../utils/parceiro_faturamento_utils.dart';
import 'searchable_dropdown.dart';

Future<void> showParceiroFaturamentoDialog(
  BuildContext context, {
  required List<int> parceiroIds,
  required bool todos,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ParceiroFaturamentoDialog(
      parceiroIds: parceiroIds,
      todos: todos,
    ),
  );
}

class ParceiroFaturamentoDialog extends StatefulWidget {
  final List<int> parceiroIds;
  final bool todos;

  const ParceiroFaturamentoDialog({
    super.key,
    required this.parceiroIds,
    required this.todos,
  });

  @override
  State<ParceiroFaturamentoDialog> createState() =>
      _ParceiroFaturamentoDialogState();
}

class _ParceiroFaturamentoDialogState extends State<ParceiroFaturamentoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _observacaoController = TextEditingController();
  String? _produtoId;
  String? _serieId;
  bool _enviando = false;
  late int _mes;
  late int _ano;
  String? _servicoNome;
  bool _observacaoEditada = false;

  @override
  void initState() {
    super.initState();
    final padrao = nfseCompetenciaPadrao(DateTime.now());
    _mes = padrao.mes;
    _ano = padrao.ano;
  }

  void _atualizarObservacaoPadrao() {
    final nome = _servicoNome;
    if (_observacaoEditada || nome == null || nome.isEmpty) return;
    _observacaoController.text =
        ParceiroFaturamentoUtils.observacaoPadraoCompetencia(nome, _mes, _ano);
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantidade = widget.todos
        ? 'todos os parceiros'
        : widget.parceiroIds.length == 1
            ? '1 parceiro'
            : '${widget.parceiroIds.length} parceiros';
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, color: GridColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Faturar $quantidade')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableDropdownField(
                label: 'Servico',
                value: _produtoId,
                valueField: 'id',
                displayField: 'nome',
                isRequired: true,
                loadPage: ParceiroFaturamentoService.buscarServicos,
                validator: (value) => value == null || value.isEmpty
                    ? 'Selecione o servico.'
                    : null,
                onChanged: (value) => setState(() => _produtoId = value),
                onItemSelected: (item) {
                  final nome = item?['nome']?.toString().trim();
                  if (nome != null && nome.isNotEmpty) {
                    _servicoNome = nome;
                    _observacaoEditada = false;
                    _atualizarObservacaoPadrao();
                  }
                },
              ),
              const SizedBox(height: 16),
              SearchableDropdownField(
                label: 'Serie NFS-e',
                value: _serieId,
                valueField: 'id',
                displayField: 'display',
                isRequired: true,
                onSearch: ParceiroFaturamentoService.buscarSeries,
                validator: (value) => value == null || value.isEmpty
                    ? 'Selecione a serie.'
                    : null,
                onChanged: (value) => setState(() => _serieId = value),
              ),
              const SizedBox(height: 16),
              _referencia(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacaoController,
                onChanged: (_) => _observacaoEditada = true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observacao',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe a observacao.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _enviando ? null : _faturar,
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.receipt_long),
          label: Text(_enviando ? 'Faturando...' : 'Faturar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// Referencia (competencia) da mensalidade: mes + ano; padrao = mes anterior.
  Widget _referencia() {
    final anoAtual = DateTime.now().year;
    final anos = {anoAtual - 2, anoAtual - 1, anoAtual, anoAtual + 1, _ano}.toList()
      ..sort();
    return Row(children: [
      Expanded(
        flex: 3,
        child: DropdownButtonFormField<int>(
          key: const Key('parceiro_faturar_mes'),
          initialValue: _mes,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Mês de referência', border: OutlineInputBorder()),
          items: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuItem(value: m, child: Text(nfseNomeMes(m))),
          ],
          onChanged: _enviando
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() => _mes = v);
                  _atualizarObservacaoPadrao();
                },
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        flex: 2,
        child: DropdownButtonFormField<int>(
          key: const Key('parceiro_faturar_ano'),
          initialValue: _ano,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Ano', border: OutlineInputBorder()),
          items: [
            for (final a in anos) DropdownMenuItem(value: a, child: Text('$a')),
          ],
          onChanged: _enviando
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() => _ano = v);
                  _atualizarObservacaoPadrao();
                },
        ),
      ),
    ]);
  }

  Future<String> _linhaConfirmacao(int id) async {
    final nome = await DropdownHelpers.parceiroLabelPorId(id.toString()) ??
        'Parceiro #$id';
    try {
      final resumo =
          await NfseFaturarService.resumo(tomadorId: id, mes: _mes, ano: _ano);
      final valor = nfseFormatarValor(nfseParseNumero(resumo['valorMensal']));
      return '$nome|R\$ $valor';
    } on NfseFaturarException catch (e) {
      return '$nome|${e.mensagem}';
    }
  }

  /// "Você vai gerar uma nota de serviço para <tomador> no valor de R$ X. Deseja continuar?"
  /// O valor exibido é o valor mensal cadastrado no tomador (o mesmo que o backend usa).
  Future<bool> _confirmar() async {
    final competencia = '${nfseNomeMes(_mes)}/$_ano';
    String texto;
    if (widget.todos) {
      texto = 'Você vai gerar uma nota de serviço (referência $competencia) '
          'para cada parceiro da empresa, cada uma no valor mensal cadastrado '
          'no respectivo parceiro.';
    } else {
      setState(() => _enviando = true);
      final linhas = await Future.wait(widget.parceiroIds.map(_linhaConfirmacao));
      if (!mounted) return false;
      setState(() => _enviando = false);
      if (linhas.length == 1) {
        final partes = linhas.first.split('|');
        texto = partes.last.startsWith('R\$')
            ? 'Você vai gerar uma nota de serviço para ${partes.first} '
                'no valor de ${partes.last} (referência $competencia).'
            : 'Não é possível faturar ${partes.first}: ${partes.last}';
      } else {
        texto = 'Você vai gerar ${linhas.length} notas de serviço '
            '(referência $competencia):\n\n'
            '${linhas.map((l) => '• ${l.replaceFirst('|', ' — ')}').join('\n')}';
      }
    }
    if (!mounted) return false;
    final continuar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar faturamento'),
        content: SelectableText('$texto\n\nDeseja continuar?',
            key: const Key('parceiro_faturar_confirmacao')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('parceiro_faturar_continuar'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return continuar == true;
  }

  Future<void> _faturar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!await _confirmar()) return;
    if (!mounted) return;
    setState(() => _enviando = true);
    final response = await ParceiroFaturamentoService.faturar(
      parceiroIds: widget.parceiroIds,
      todos: widget.todos,
      produtoId: int.parse(_produtoId!),
      serieId: int.parse(_serieId!),
      observacao: _observacaoController.text,
      mesReferencia: _mes,
      anoReferencia: _ano,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!response.isSuccess || response.body == null) {
      _mostrarResultado(
        titulo: 'Faturamento nao concluido',
        mensagem: _mensagemErro(response.body, response.statusCode),
        erro: true,
      );
      return;
    }

    final body = response.body!;
    final falhas = (body['falhas'] as num?)?.toInt() ?? 0;
    final sucessos = (body['sucessos'] as num?)?.toInt() ?? 0;
    final resultados =
        body['resultados'] is List ? body['resultados'] as List : const [];
    final detalhes = resultados
        .whereType<Map>()
        .where((item) => item['sucesso'] != true)
        .map((item) => '${item['parceiroNome'] ?? 'Parceiro'}: '
            '${item['mensagem'] ?? 'Falha sem detalhe'}')
        .join('\n');
    _mostrarResultado(
      titulo: falhas == 0 ? 'Faturamento concluido' : 'Faturamento finalizado',
      mensagem: '$sucessos sucesso(s) e $falhas falha(s).'
          '${detalhes.isEmpty ? '' : '\n\n$detalhes'}',
      erro: falhas > 0,
      fecharOrigem: true,
    );
  }

  void _mostrarResultado({
    required String titulo,
    required String mensagem,
    required bool erro,
    bool fecharOrigem = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(titulo),
        content: SelectableText(mensagem),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (fecharOrigem && mounted) Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static String _mensagemErro(Map<String, dynamic>? body, int status) {
    final mensagem = body?['message'] ?? body?['mensagem'] ?? body?['error'];
    return mensagem?.toString().trim().isNotEmpty == true
        ? mensagem.toString()
        : 'Erro HTTP $status.';
  }
}
