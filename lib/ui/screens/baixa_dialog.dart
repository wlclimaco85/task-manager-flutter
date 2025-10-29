// baixa_dialog.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

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

  final CustomColors colors = CustomColors();

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toString();
    _loadData();
  }

  Future<void> _loadData() async {
    final formasMap = await FormaPagamento.loadFormasPagamento();
    final contasMap = await ContaBancariaCaller.loadContas();

    setState(() {
      _formasPagamento = formasMap
          .map((map) => FormaPagamento(
                id: map['value'],
                nome: map['label'],
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
    return AlertDialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Registrar Baixa',
        style: TextStyle(
          color: colors.getDarkGreenBorder(),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _valorController,
                      label: 'Valor da Baixa',
                      icon: Icons.attach_money,
                      validatorMsg: 'Informe o valor da baixa',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      label: 'Forma de Pagamento',
                      icon: Icons.payment,
                      value: _formaPagamentoId,
                      items: _formasPagamento
                          .map((f) => DropdownMenuItem(
                              value: f.id, child: Text(f.nome ?? '')))
                          .toList(),
                      onChanged: (v) => setState(() => _formaPagamentoId = v),
                      validatorMsg: 'Selecione a forma de pagamento',
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      label: 'Conta Bancária',
                      icon: Icons.account_balance,
                      value: _contaId,
                      items: _contas
                          .map((c) => DropdownMenuItem<int>(
                              value: c['value'] as int,
                              child: Text(c['label']?.toString() ?? '')))
                          .toList(),
                      onChanged: (v) => setState(() => _contaId = v),
                      validatorMsg: 'Selecione a conta bancária',
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
                          onPressed: () => _selectDate(context),
                          child: Text(
                            '${_dataBaixa.day}/${_dataBaixa.month}/${_dataBaixa.year}',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.getConfirmButtonColor(),
            foregroundColor: colors.getButtonTextColor(),
          ),
          onPressed: _submitBaixa,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMsg,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: GridColors.inputBorder),
        filled: true,
        fillColor: GridColors.inputBackground,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.getBorderInput(), width: 1.5),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (v) => (v == null || v.isEmpty) ? validatorMsg : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String validatorMsg,
    T? value,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: GridColors.inputBorder),
        filled: true,
        fillColor: GridColors.inputBackground,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.getBorderInput(), width: 1.5),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: (value) => (value == null) ? validatorMsg : null,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataBaixa) {
      setState(() => _dataBaixa = picked);
    }
  }

  Future<void> _submitBaixa() async {
    if (_formKey.currentState!.validate()) {
      final valorBaixa = double.parse(_valorController.text);

      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()),
        {
          'dataBaixa': _dataBaixa.toIso8601String(),
          'valorBaixa': valorBaixa,
          'formaPagamentoId': _formaPagamentoId,
          'contaId': _contaId,
        },
      );

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Baixa registrada com sucesso!'),
            backgroundColor: colors.getShowSnackBarSuccess(),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar baixa: ${response.statusCode}'),
            backgroundColor: colors.getShowSnackBarError(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}
