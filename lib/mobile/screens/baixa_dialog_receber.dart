import 'package:flutter/material.dart';
import '../../../models/conta_receber_model.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';

class BaixaDialogReceber extends StatefulWidget {
  final ContaReceber conta;

  const BaixaDialogReceber({super.key, required this.conta});

  @override
  State<BaixaDialogReceber> createState() => _BaixaDialogReceberState();
}

class _BaixaDialogReceberState extends State<BaixaDialogReceber> {
  final _formKey = GlobalKey<FormState>();
  final _valorBaixaController = TextEditingController();
  final _valorMultaController = TextEditingController();
  final _valorJurosController = TextEditingController();
  final _valorDescontoController = TextEditingController();

  DateTime _dataBaixa = DateTime.now();
  int? _contaId;
  int? _formaPagamentoId;
  bool _isLoading = true;

  List<Map<String, dynamic>> _contas = [];
  List<FormaPagamento> _formasPagamento = [];

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toStringAsFixed(2);
    _valorMultaController.text =
        widget.conta.valorMulta?.toStringAsFixed(2) ?? '0.00';
    _valorJurosController.text =
        widget.conta.valorJuros?.toStringAsFixed(2) ?? '0.00';
    _valorDescontoController.text =
        widget.conta.valorDesconto?.toStringAsFixed(2) ?? '0.00';
    _loadData();
  }

  Future<void> _loadData() async {
    final contas = await ContaBancariaCaller.loadContas();
    final formasMap = await FormaPagamento.loadFormasPagamento();
    if (!mounted) return;
    setState(() {
      _contas = contas;
      _formasPagamento = formasMap
          .map((m) => FormaPagamento(
                id: m['value'],
                nome: m['label'],
                descricao: '',
                status: 'Ativo',
                audit: null,
              ))
          .toList();
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
          Icon(Icons.monetization_on, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Baixar Conta a Receber',
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
                        color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
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
                      controller: _valorBaixaController,
                      decoration: const InputDecoration(
                        labelText: 'Valor da Baixa',
                        prefixIcon: Icon(Icons.monetization_on),
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

                    // Multa e Juros lado a lado
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _valorMultaController,
                            decoration: const InputDecoration(
                              labelText: 'Multa',
                              prefixIcon: Icon(Icons.percent, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _valorJurosController,
                            decoration: const InputDecoration(
                              labelText: 'Juros',
                              prefixIcon:
                                  Icon(Icons.trending_up, size: 18),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Desconto
                    TextFormField(
                      controller: _valorDescontoController,
                      decoration: const InputDecoration(
                        labelText: 'Desconto',
                        prefixIcon: Icon(Icons.sell_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // Forma de pagamento
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Forma de Pagamento',
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(),
                      ),
                      value: _formaPagamentoId,
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
                      value: _contaId,
                      items: _contas
                          .map<DropdownMenuItem<int>>(
                            (c) => DropdownMenuItem<int>(
                              value: c['value'] as int,
                              child: Text(c['label'],
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _contaId = v),
                      validator: (v) =>
                          v == null ? 'Selecione a conta bancária' : null,
                    ),
                    const SizedBox(height: 12),

                    // Data da baixa
                    InkWell(
                      onTap: () => _pickDate(context),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _baixar,
          child: const Text('Confirmar Baixa'),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) setState(() => _dataBaixa = d);
  }

  Future<void> _baixar() async {
    if (!_formKey.currentState!.validate()) return;

    final valorBaixa =
        double.tryParse(_valorBaixaController.text.replaceAll(',', '.')) ?? 0;
    final valorMulta =
        double.tryParse(_valorMultaController.text.replaceAll(',', '.')) ?? 0;
    final valorJuros =
        double.tryParse(_valorJurosController.text.replaceAll(',', '.')) ?? 0;
    final valorDesconto =
        double.tryParse(_valorDescontoController.text.replaceAll(',', '.')) ?? 0;

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.registrarBaixaContaReceber(widget.conta.id.toString()),
      {
        'dataBaixa': _dataBaixa.toIso8601String(),
        'valorBaixa': valorBaixa,
        'valorMulta': valorMulta,
        'valorJuros': valorJuros,
        'valorDesconto': valorDesconto,
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

    if (response.isSuccess) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _valorBaixaController.dispose();
    _valorMultaController.dispose();
    _valorJurosController.dispose();
    _valorDescontoController.dispose();
    super.dispose();
  }
}
