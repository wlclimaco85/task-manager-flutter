import 'package:flutter/material.dart';

import '../services/parceiro_faturamento_service.dart';
import '../utils/grid_colors.dart';
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
                    _observacaoController.text =
                        ParceiroFaturamentoService.observacaoPadrao(
                            nome, DateTime.now());
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
              TextFormField(
                controller: _observacaoController,
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

  Future<void> _faturar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviando = true);
    final response = await ParceiroFaturamentoService.faturar(
      parceiroIds: widget.parceiroIds,
      todos: widget.todos,
      produtoId: int.parse(_produtoId!),
      serieId: int.parse(_serieId!),
      observacao: _observacaoController.text,
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
