import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/data/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

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
    return AlertDialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Baixar Conta a Receber',
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
                    _buildTextField(_valorBaixaController, 'Valor da Baixa'),
                    _buildTextField(_valorMultaController, 'Valor da Multa'),
                    _buildTextField(_valorJurosController, 'Valor dos Juros'),
                    _buildTextField(
                        _valorDescontoController, 'Valor do Desconto'),
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      label: 'Conta Bancária',
                      icon: Icons.account_balance,
                      value: _contaId,
                      items: _contas
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['value'],
                              child: Text(
                                c['label'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
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
          onPressed: _baixarConta,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
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
      isExpanded: true,
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dataBaixa = picked);
  }

  void _baixarConta() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Baixa registrada com sucesso!'),
          backgroundColor: colors.getShowSnackBarSuccess(),
        ),
      );
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
