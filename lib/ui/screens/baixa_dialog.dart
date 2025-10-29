import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/conta_pagar_model.dart';
import 'package:task_manager_flutter/data/models/forma_pagamento_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class BaixaDialog extends StatefulWidget {
  final ContaPagar conta;

  const BaixaDialog({super.key, required this.conta});

  /// 🪄 Mostra o diálogo com fade, slide e blur
  static Future<void> show(BuildContext context, ContaPagar conta) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "Registrar Baixa",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) => Center(
        child: Material(
            color: Colors.transparent, child: BaixaDialog(conta: conta)),
      ),
      transitionBuilder: (context, anim, _, child) {
        final offsetAnim = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
            opacity: anim,
            child: SlideTransition(position: offsetAnim, child: child),
          ),
        );
      },
    );
  }

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
          .map((m) => FormaPagamento(
              id: m['value'],
              nome: m['label'],
              descricao: '',
              status: 'Ativo',
              audit: null))
          .toList();
      _contas = contasMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AlertDialog(
        backgroundColor: GridColors.dialogBackground.withOpacity(0.95),
        elevation: 12,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Registrar Baixa',
            style: TextStyle(
                color: colors.getDarkGreenBorder(),
                fontWeight: FontWeight.bold)),
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _buildTextField(_valorController, 'Valor da Baixa',
                        Icons.attach_money, 'Informe o valor'),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                        'Forma de Pagamento',
                        Icons.payment,
                        _formaPagamentoId,
                        _formasPagamento
                            .map((f) => DropdownMenuItem(
                                value: f.id, child: Text(f.nome ?? '')))
                            .toList(),
                        (v) => setState(() => _formaPagamentoId = v),
                        'Selecione a forma'),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                        'Conta Bancária',
                        Icons.account_balance,
                        _contaId,
                        _contas
                            .map((c) => DropdownMenuItem<int>(
                                value: c['value'] as int,
                                child: Text(c['label'],
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        (v) => setState(() => _contaId = v),
                        'Selecione a conta'),
                    const SizedBox(height: 16),
                    Row(children: [
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
                                  color: GridColors.primary)))
                    ])
                  ]),
                ),
              ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: colors.getCancelButtonColor(),
                  foregroundColor: colors.getButtonTextColor()),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.getConfirmButtonColor(),
                  foregroundColor: colors.getButtonTextColor()),
              onPressed: _submitBaixa,
              child: const Text('Confirmar'))
        ],
      ),
    );
  }

  Widget _buildTextField(
          TextEditingController c, String label, IconData icon, String msg) =>
      TextFormField(
          controller: c,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: GridColors.inputBorder),
              filled: true,
              fillColor: GridColors.inputBackground,
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.getBorderInput(), width: 1.2)),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.getBorderInput(), width: 1.5))),
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.isEmpty) ? msg : null);

  Widget _buildDropdown<T>(
          String label,
          IconData icon,
          T? value,
          List<DropdownMenuItem<T>> items,
          void Function(T?) onChanged,
          String msg) =>
      DropdownButtonFormField<T>(
          isExpanded: true,
          value: value,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: GridColors.inputBorder),
              filled: true,
              fillColor: GridColors.inputBackground,
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.getBorderInput(), width: 1.2)),
              focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: colors.getBorderInput(), width: 1.5))),
          items: items,
          onChanged: onChanged,
          validator: (v) => (v == null) ? msg : null);

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _dataBaixa,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (picked != null) setState(() => _dataBaixa = picked);
  }

  Future<void> _submitBaixa() async {
    if (_formKey.currentState!.validate()) {
      final valorBaixa = double.parse(_valorController.text);
      final res = await NetworkCaller().postRequest(
          ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()), {
        'dataBaixa': _dataBaixa.toIso8601String(),
        'valorBaixa': valorBaixa,
        'formaPagamentoId': _formaPagamentoId,
        'contaId': _contaId
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.isSuccess
              ? 'Baixa registrada com sucesso!'
              : 'Erro: ${res.statusCode}'),
          backgroundColor: res.isSuccess
              ? colors.getShowSnackBarSuccess()
              : colors.getShowSnackBarError()));
      if (res.isSuccess) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}
