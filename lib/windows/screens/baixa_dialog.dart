// baixa_dialog.dart
import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_texts.dart';

class BaixaDialog extends StatefulWidget {
  final ContaPagar conta;

  const BaixaDialog({super.key, required this.conta});

  @override
  _BaixaDialogState createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<BaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  DateTime _dataBaixa = DateTime.now();
  int? _formaPagamentoId; // Armazena o ID selecionado
  bool _isLoading = true;
  List<FormaPagamento> _formasPagamento = [];

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toString();
    _loadFormasPagamento();
  }

  Future<void> _loadFormasPagamento() async {
    final List<Map<String, dynamic>> formasMap =
        await FormaPagamento.loadFormasPagamento(); // retorna List<Map>

    final List<FormaPagamento> formas = formasMap
        .map(
          (map) => FormaPagamento(
            id: map['value'],
            nome: map['label'],
            descricao: '',
            status: 'Ativo',
            audit: null,
          ),
        )
        .toList();
    setState(() {
      _formasPagamento = formas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Baixa'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo Valor da Baixa
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
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

              // Dropdown Formas de Pagamento
              _isLoading
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<int>(
                      initialValue: _formaPagamentoId,
                      decoration: const InputDecoration(
                        labelText: 'Forma de Pagamento',
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: _formasPagamento.map((forma) {
                        return DropdownMenuItem<int>(
                          value: forma.id, // Acessa o ID do objeto
                          child: Text(
                            forma.nome ?? '',
                          ), // Acessa o nome do objeto
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _formaPagamentoId = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecione a forma de pagamento';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Seletor de Data
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  const Text('Data da Baixa:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      '${_dataBaixa.day}/${_dataBaixa.month}/${_dataBaixa.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _submitBaixa,
          child: const Text('Confirmar Baixa'),
        ),
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

      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()),
        {
          'dataBaixa': _dataBaixa.toIso8601String(),
          'valorBaixa': valorBaixa,
          'formaPagamentoId': _formaPagamentoId,
        },
      );

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Baixa registrada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao registrar baixa: ${response ?? response.statusCode}',
            ),
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
