import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/constants/show_general_dialog.dart';

// se já tiver showM3Dialog e BaixaInfo, remova imports duplicados
// import 'show_m3_dialog.dart';

class BaixaDialogReceber extends StatefulWidget {
  final ContaReceber conta;

  const BaixaDialogReceber({super.key, required this.conta});

  static Future<void> show(BuildContext context, ContaReceber conta) {
    return showM3Dialog(
      context: context,
      barrierLabel: 'Baixar Conta a Receber',
      child: BaixaDialogReceber(conta: conta),
    );
  }

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

  final CustomColors colors = CustomColors();

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toStringAsFixed(2);
    _valorMultaController.text = (widget.conta.valorMulta ?? 0).toString();
    _valorJurosController.text = (widget.conta.valorJuros ?? 0).toString();
    _valorDescontoController.text =
        (widget.conta.valorDesconto ?? 0).toString();
    _loadData();
  }

  Future<void> _loadData() async {
    // contas bancárias
    _contas = await ContaBancariaCaller.loadContas();
    // formas de pagamento (mesma fonte usada no Pagar)
    final formasMap = await FormaPagamento.loadFormasPagamento();
    _formasPagamento = formasMap
        .map((m) => FormaPagamento(
              id: m['value'],
              nome: m['label'],
              descricao: '',
              status: 'Ativo',
              audit: null,
            ))
        .toList();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AlertDialog(
        backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 12,
        shadowColor: Colors.black26,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          'Baixar Conta a Receber',
          style: TextStyle(
            color: colors.getDarkGreenBorder(),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: _isLoading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildText(_valorBaixaController, 'Valor da Baixa'),
                      const SizedBox(height: 12),
                      _buildText(_valorMultaController, 'Valor da Multa'),
                      const SizedBox(height: 12),
                      _buildText(_valorJurosController, 'Valor dos Juros'),
                      const SizedBox(height: 12),
                      _buildText(_valorDescontoController, 'Valor do Desconto'),
                      const SizedBox(height: 16),
                      _buildDropdown<int>(
                        'Forma de Pagamento',
                        Icons.payment,
                        _formaPagamentoId,
                        _formasPagamento
                            .map(
                              (f) => DropdownMenuItem<int>(
                                value: f.id,
                                child: Text(f.nome ?? ''),
                              ),
                            )
                            .toList(),
                        (v) => setState(() => _formaPagamentoId = v),
                        'Selecione a forma de pagamento',
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown<int>(
                        'Conta Bancária',
                        Icons.account_balance,
                        _contaId,
                        _contas
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['value'] as int,
                                child: Text(
                                  c['label'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        (v) => setState(() => _contaId = v),
                        'Selecione a conta',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 20, color: GridColors.inputBorder),
                          const SizedBox(width: 8),
                          const Text('Data da Baixa:'),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _pickDate(context),
                            child: Text(
                              '${_dataBaixa.day.toString().padLeft(2, '0')}/${_dataBaixa.month.toString().padLeft(2, '0')}/${_dataBaixa.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: GridColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: colors.getCancelButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.getConfirmButtonColor(),
              foregroundColor: colors.getButtonTextColor(),
            ),
            onPressed: _baixar,
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildText(TextEditingController c, String label) => TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.monetization_on, color: GridColors.inputBorder),
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        keyboardType: TextInputType.number,
        validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
      );

  Widget _buildDropdown<T>(
    String label,
    IconData icon,
    T? value,
    List<DropdownMenuItem<T>> items,
    void Function(T?) onChanged,
    String msg,
  ) =>
      DropdownButtonFormField<T>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: GridColors.inputBorder),
          filled: true,
          fillColor: GridColors.inputBackground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: items,
        onChanged: onChanged,
        validator: (v) => (v == null) ? msg : null,
      );

  Future<void> _pickDate(BuildContext c) async {
    final d = await showDatePicker(
      context: c,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _dataBaixa = d);
  }

  void _baixar() {
    if (!_formKey.currentState!.validate()) return;

    // Aqui você chamaria sua API de baixa de receber
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Baixa registrada com sucesso!'),
        backgroundColor: colors.getShowSnackBarSuccess(),
      ),
    );
    Navigator.pop(context, true);
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
