import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/conta_receber_model.dart';
import 'package:task_manager_flutter/data/models/conta_pagar_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

class BaixaDialog extends StatefulWidget {
  final dynamic conta;
  final bool isReceber;

  const BaixaDialog({super.key, required this.conta, this.isReceber = false});

  @override
  _BaixaDialogState createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<BaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  DateTime _dataBaixa = DateTime.now();
  String? _formaPagamento;

  final List<String> _formasPagamento = [
    'Dinheiro',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Transferência',
    'PIX',
    'Boleto',
    'Cheque',
  ];

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Registrar Baixa - ${widget.isReceber ? 'Recebimento' : 'Pagamento'}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valorController,
                decoration: InputDecoration(
                  labelText: 'Valor da Baixa',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor da baixa';
                  }
                  final valor = double.tryParse(value);
                  if (valor == null || valor <= 0) {
                    return 'Valor deve ser maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _formaPagamento,
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _formasPagamento.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _formaPagamento = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione a forma de pagamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 8),
                  Text('Data da Baixa:'),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      '${_dataBaixa.day}/${_dataBaixa.month}/${_dataBaixa.year}',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _submitBaixa, child: Text('Confirmar Baixa')),
      ],
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
      setState(() {
        _dataBaixa = picked;
      });
    }
  }

  void _submitBaixa() async {
    if (_formKey.currentState!.validate()) {
      final valorBaixa = double.parse(_valorController.text);

      final endpoint = widget.isReceber
          ? ApiLinks.registrarBaixaContaReceber(widget.conta.id.toString())
          : ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString());

      final NetworkResponse response = await NetworkCaller()
          .postRequest(endpoint, {
            'dataBaixa': _dataBaixa.toIso8601String(),
            'valorBaixa': valorBaixa,
            'formaPagamento': _formaPagamento,
          });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Baixa registrada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: ${response}')));
      }
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}
