import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';

class ProductRegisterScreen extends StatefulWidget {
  const ProductRegisterScreen({Key? key}) : super(key: key);

  @override
  _ProductRegisterScreenState createState() => _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends State<ProductRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = true;
  bool isSubmitting = false;

  String vendedorEndereco = '';
  String compradorEndereco = '';
  List<Map<String, dynamic>> classificacoes = [];

  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController qtdSacosController = TextEditingController();
  final TextEditingController vlrSacosController = TextEditingController();
  final List<TextEditingController> classificacaoControllers = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<Parceiro> parceiroData =
          await ParceiroCaller().fetchParceiros(6);

      setState(() {
        vendedorEndereco =
            '${parceiroData[0].endereco!.cidade}, ${parceiroData[0].endereco!.bairro}, ${parceiroData[0].endereco!.estado}';
      });

      final List<Account> classificacoesData =
          await VendasCaller().fetchClassificacao();

      classificacoes = classificacoesData
          .expand((classificacao) => (classificacao.valores as List).map(
              (valor) => {'descricao': valor.descricao, 'valor': valor.valor}))
          .toList();

      classificacaoControllers.addAll(
        classificacoes.map((_) => TextEditingController(text: '0')).toList(),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
    });

    final List<Map<String, dynamic>> classificacaoList = [];
    for (int i = 0; i < classificacoes.length; i++) {
      classificacaoList.add({
        'descricao': classificacoes[i]['descricao'],
        'valor': double.tryParse(classificacaoControllers[i].text) ?? 0,
      });
    }

    final Map<String, dynamic> requestBody = {
      'tipoProdutoId': 1,
      'produtoId': 1,
      'descricao': descricaoController.text,
      'listFotos': [
        {'foto': 'sdfsdfsdfsdf', 'isPrincipal': true}
      ],
      'qtdSacos': int.tryParse(qtdSacosController.text) ?? 0,
      'vlrSacos': double.tryParse(vlrSacosController.text) ?? 0,
      'isCargaFechada': true,
      'parceiro': {'id': 4},
      'status': 'A',
      'classificacao': classificacaoList,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.41:8088/boletobancos/api/produtos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
        _formKey.currentState!.reset();
        descricaoController.clear();
        qtdSacosController.clear();
        vlrSacosController.clear();
        classificacaoControllers.forEach((controller) => controller.clear());
      } else {
        throw Exception('Erro ao cadastrar produto.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar formulário: $error')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  InputDecoration customInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9), // Fundo verde clarinho
      appBar: AppBar(
        title: const Text('Cadastro de Produto'),
        actions: [
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Retirada: $vendedorEndereco'),
                        const SizedBox(height: 16),

                        // Descrição
                        TextFormField(
                          controller: descricaoController,
                          decoration:
                              customInputDecoration('Descrição do Produto'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Quantidade de sacos
                        TextFormField(
                          controller: qtdSacosController,
                          decoration:
                              customInputDecoration('Quantidade de Sacos'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || int.tryParse(value) == null
                                  ? 'Número inválido'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        // Valor por saco
                        TextFormField(
                          controller: vlrSacosController,
                          decoration: customInputDecoration('Valor por Saco'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value == null || double.tryParse(value) == null
                                  ? 'Valor inválido'
                                  : null,
                        ),

                        const SizedBox(height: 16),

                        // Classificações
                        const Text(
                          'Classificações',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (int i = 0; i < classificacoes.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: TextFormField(
                              controller: classificacaoControllers[i],
                              decoration: customInputDecoration(
                                  classificacoes[i]['descricao']),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Botão Flutuante no Canto Inferior Direito
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FloatingActionButton.extended(
                      onPressed: isSubmitting ? null : submitForm,
                      label: isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('Gravar'),
                      icon: const Icon(Icons.save),
                      backgroundColor:
                          isSubmitting ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
