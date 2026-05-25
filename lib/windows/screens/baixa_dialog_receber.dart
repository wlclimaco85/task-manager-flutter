import 'package:flutter/material.dart';
import '../../../models/conta_receber_model.dart';
import '../../utils/grid_texts.dart';

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

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toString();
    _valorMultaController.text = widget.conta.valorMulta?.toString() ?? '0';
    _valorJurosController.text = widget.conta.valorJuros?.toString() ?? '0';
    _valorDescontoController.text =
        widget.conta.valorDesconto?.toString() ?? '0';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GridTexts.receiveAccountLow,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge, // This is the correct replacement
              ),
              const SizedBox(height: 16),
              Text(GridTexts.descriptionLabel(widget.conta.descricao)),
              Text(
                GridTexts.originalValueLabel(
                  '${GridTexts.currencySymbol}${widget.conta.valor.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorBaixaController,
                decoration: const InputDecoration(labelText: GridTexts.lowValue),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _valorMultaController,
                decoration: const InputDecoration(labelText: GridTexts.fineValue),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _valorJurosController,
                decoration: const InputDecoration(labelText: GridTexts.interestValue),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _valorDescontoController,
                decoration: const InputDecoration(
                  labelText: GridTexts.discountValue,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(GridTexts.lowDateLabel(_formatDate(_dataBaixa))),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(GridTexts.cancel),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _baixarConta,
                    child: const Text(GridTexts.confirmLow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataBaixa) {
      setState(() {
        _dataBaixa = picked;
      });
    }
  }

  void _baixarConta() {
    if (_formKey.currentState!.validate()) {
      // Implementar lógica de baixa aqui
      Navigator.pop(context);
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
