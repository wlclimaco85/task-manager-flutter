import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  bool useCustomAddress = false;

  String selectedTipoProduto = "Arroz em Casca";
  String vendedorEndereco = '';
  List<Map<String, dynamic>> classificacoes = [];
  List<File> selectedImages = [];
  File? principalImage;

  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController qtdSacosController = TextEditingController();
  final TextEditingController vlrSacosController = TextEditingController();
  final List<TextEditingController> classificacaoControllers = [];

  // Campos para endereço customizado
  final TextEditingController ruaController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController cepController = TextEditingController();

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

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null && images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void setPrincipalImage(File image) {
    setState(() {
      principalImage = image;
    });
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

    final List<Map<String, dynamic>> imageList = selectedImages.map((image) {
      final String base64Image = base64Encode(image.readAsBytesSync());
      return {
        'foto': base64Image,
        'isPrincipal': image == principalImage,
      };
    }).toList();

    final Map<String, dynamic> customAddress = {
      'rua': ruaController.text,
      'numero': numeroController.text,
      'bairro': bairroController.text,
      'cidade': cidadeController.text,
      'estado': estadoController.text,
      'cep': cepController.text,
    };

    final Map<String, dynamic> requestBody = {
      'tipoProdutoId': 1, // Exemplo: ID para "Arroz em Casca"
      'produtoId': 1,
      'descricao': descricaoController.text,
      'listFotos': imageList,
      'qtdSacos': int.tryParse(qtdSacosController.text) ?? 0,
      'vlrSacos': double.tryParse(vlrSacosController.text) ?? 0,
      'isCargaFechada': true,
      'parceiro': {'id': 4},
      'status': 'A',
      'classificacao': classificacaoList,
      if (useCustomAddress) 'enderecoRetirada': customAddress,
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
        ruaController.clear();
        numeroController.clear();
        bairroController.clear();
        cidadeController.clear();
        estadoController.clear();
        cepController.clear();
        selectedImages.clear();
        principalImage = null;
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
      backgroundColor: const Color(0xFFE8F5E9),
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
                        Row(
                          children: [
                            const Text('Usar outro endereço para retirada?'),
                            Checkbox(
                              value: useCustomAddress,
                              onChanged: (value) {
                                setState(() {
                                  useCustomAddress = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        if (useCustomAddress) ...[
                          TextFormField(
                            controller: ruaController,
                            decoration: customInputDecoration('Rua'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: numeroController,
                            decoration: customInputDecoration('Número'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: bairroController,
                            decoration: customInputDecoration('Bairro'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: cidadeController,
                            decoration: customInputDecoration('Cidade'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: estadoController,
                            decoration: customInputDecoration('Estado'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: cepController,
                            decoration: customInputDecoration('CEP'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo obrigatório'
                                : null,
                          ),
                        ],

                        const SizedBox(height: 16),
                        // Dropdown para tipo de produto
                        DropdownButtonFormField<String>(
                          value: selectedTipoProduto,
                          decoration: customInputDecoration('Tipo de Produto'),
                          items: ['Arroz em Casca', 'Outro Produto']
                              .map((tipo) => DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTipoProduto = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Upload de Fotos
                        ElevatedButton.icon(
                          onPressed: pickImages,
                          icon: const Icon(Icons.photo),
                          label: const Text("Adicionar Fotos"),
                        ),
                        Wrap(
                          spacing: 8,
                          children: selectedImages.map((image) {
                            return GestureDetector(
                              onTap: () => setPrincipalImage(image),
                              child: Stack(
                                children: [
                                  Image.file(
                                    image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  if (principalImage == image)
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Restante do formulário
                        TextFormField(
                          controller: descricaoController,
                          decoration:
                              customInputDecoration('Descrição do Produto'),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Campo obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 16),
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
