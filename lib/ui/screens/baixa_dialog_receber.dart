import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class BaixaDialogReceber extends StatefulWidget {
  final ContaReceber conta;

  const BaixaDialogReceber({super.key, required this.conta});

  static Future<void> show(BuildContext context, ContaReceber conta) {
    return showGeneralDialog(
      context: context,
      barrierLabel: "Baixar Conta a Receber",
      barrierDismissible: true,
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Center(
        child: Material(
            color: Colors.transparent, child: BaixaDialogReceber(conta: conta)),
      ),
      transitionBuilder: (_, anim, __, child) {
        final offsetAnim = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
              opacity: anim,
              child: SlideTransition(position: offsetAnim, child: child)),
        );
      },
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
  bool _isLoading = true;
  List<Map<String, dynamic>> _contas = [];
  final CustomColors colors = CustomColors();

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toString();
    _valorMultaController.text = widget.conta.valorMulta?.toString() ?? '0';
    _valorJurosController.text = widget.conta.valorJuros?.toString() ?? '0';
    _valorDescontoController.text =
        widget.conta.valorDesconto?.toString() ?? '0';
    _loadContas();
  }

  Future<void> _loadContas() async {
    _contas = await ContaBancariaCaller.loadContas();
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
        title: Text('Baixar Conta a Receber',
            style: TextStyle(
                color: colors.getDarkGreenBorder(),
                fontWeight: FontWeight.bold)),
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _buildText(_valorBaixaController, 'Valor da Baixa'),
                      _buildText(_valorMultaController, 'Valor da Multa'),
                      _buildText(_valorJurosController, 'Valor dos Juros'),
                      _buildText(_valorDescontoController, 'Valor do Desconto'),
                      const SizedBox(height: 16),
                      _buildDropdown<int>(
                          'Conta Bancária',
                          Icons.account_balance,
                          _contaId,
                          _contas
                              .map<DropdownMenuItem<int>>((c) =>
                                  DropdownMenuItem<int>(
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
                        TextButton(
                            onPressed: () => _pickDate(context),
                            child: Text(
                                '${_dataBaixa.day}/${_dataBaixa.month}/${_dataBaixa.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: GridColors.primary)))
                      ])
                    ]))),
        actions: [
          TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: colors.getCancelButtonColor(),
                  foregroundColor: colors.getButtonTextColor()),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.getConfirmButtonColor(),
                  foregroundColor: colors.getButtonTextColor()),
              onPressed: _baixar,
              child: const Text('Confirmar'))
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
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colors.getBorderInput(), width: 1.5),
          ),
        ),
        keyboardType: TextInputType.number,
      );

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

  Future<void> _pickDate(BuildContext c) async {
    final d = await showDatePicker(
        context: c,
        initialDate: _dataBaixa,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d != null) setState(() => _dataBaixa = d);
  }

  void _baixar() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Baixa registrada com sucesso!'),
          backgroundColor: colors.getShowSnackBarSuccess()));
      Navigator.pop(context, true);
    }
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
