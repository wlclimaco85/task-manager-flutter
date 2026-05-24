import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_texts.dart';

class BaixaDialog extends StatefulWidget {
  final ContaPagar conta;

  const BaixaDialog({super.key, required this.conta});

  @override
  State<BaixaDialog> createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<BaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  DateTime _dataBaixa = DateTime.now();
  int? _formaPagamentoId;
  int? _contaId;
  bool _isLoading = true;

  List<FormaPagamento> _formasPagamento = [];
  List<Map<String, dynamic>> _contas = [];

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toStringAsFixed(2);
    _loadData();
  }

  Future<void> _loadData() async {
    final formasMap = await FormaPagamento.loadFormasPagamento();
    final contasMap = await ContaBancariaCaller.loadContas();
    if (!mounted) return;
    setState(() {
      _formasPagamento = formasMap
          .map((m) => FormaPagamento(
                id: m['value'],
                nome: m['label'],
                descricao: '',
                status: 'Ativo',
                audit: null,
              ))
          .toList();
      _contas = contasMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.payment, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Registrar Baixa',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Informações da conta
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.conta.descricao,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            'Valor original: R\$ ${widget.conta.valor.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Valor da baixa
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(
                        labelText: 'Valor da Baixa',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o valor';
                        final val = double.tryParse(v.replaceAll(',', '.'));
                        if (val == null || val <= 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Forma de pagamento
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Forma de Pagamento',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _formaPagamentoId,
                      items: _formasPagamento
                          .map((f) => DropdownMenuItem<int>(
                              value: f.id, child: Text(f.nome ?? '')))
                          .toList(),
                      onChanged: (v) => setState(() => _formaPagamentoId = v),
                      validator: (v) =>
                          v == null ? 'Selecione a forma de pagamento' : null,
                    ),
                    const SizedBox(height: 12),

                    // Conta bancária
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Conta Bancária',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _contaId,
                      items: _contas
                          .map((c) => DropdownMenuItem<int>(
                                value: c['value'] as int,
                                child: Text(c['label'],
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _contaId = v),
                      validator: (v) =>
                          v == null ? 'Selecione a conta bancária' : null,
                    ),
                    const SizedBox(height: 12),

                    // Data da baixa
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data da Baixa',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_dataBaixa.day.toString().padLeft(2, '0')}/'
                          '${_dataBaixa.month.toString().padLeft(2, '0')}/'
                          '${_dataBaixa.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _submitBaixa,
          child: const Text('Confirmar Baixa'),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _dataBaixa = picked);
  }

  Future<void> _submitBaixa() async {
    if (!_formKey.currentState!.validate()) return;

    final valorBaixa =
        double.parse(_valorController.text.replaceAll(',', '.'));

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()),
      {
        'dataBaixa': _dataBaixa.toIso8601String(),
        'valorBaixa': valorBaixa,
        'formaPagamentoId': _formaPagamentoId,
        'contaId': _contaId,
      },
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.isSuccess
          ? 'Baixa registrada com sucesso!'
          : 'Erro ao registrar baixa: ${response.statusCode}'),
      backgroundColor:
          response.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
    ));

    if (response.isSuccess) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}
