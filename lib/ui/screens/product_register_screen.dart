import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/models/venda_model.dart';
import 'package:task_manager_flutter/data/services/vendas_caller.dart';
import 'package:task_manager_flutter/data/services/parceiro_caller.dart';
import 'package:task_manager_flutter/data/models/parceiro_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

// Define theme colors
Color lightGreenBackground = CustomColors().getLightGreenBackground();
Color darkGreenBorder = CustomColors().getDarkGreenBorder();
Color buttonBackground = CustomColors().getButtonBackground();

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
  bool isCargaFechada = false;

  String selectedTipoProduto = "Arroz em Casca";
  String selectedTipoGrao = "Verde";
  DateTime? dtRetirada;
  final TextEditingController dtRetiradaController = TextEditingController();

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
    initializeDateFormatting('pt_BR', null).then((_) {
      fetchInitialData();
    });
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<Parceiro> parceiroData = await ParceiroCaller()
          .fetchParceiros(context, AuthUtility.userInfo?.data?.id ?? 0);

      setState(() {
        vendedorEndereco =
            '${parceiroData[0].endereco!.bairro},  ${parceiroData[0].endereco!.cidade},  ${parceiroData[0].endereco!.estado}';
      });

      final List<Account> classificacoesData =
          await VendasCaller().fetchClassificacao(context);

      classificacoes = classificacoesData
          .expand((classificacao) => (classificacao.valores as List).map(
              (valor) => {'descricao': valor.descricao, 'valor': valor.valor}))
          .toList();

      await Future.delayed(const Duration(seconds: 1)); // Simulação de atraso
      setState(() {
        classificacaoControllers.addAll(
          classificacoes.map((_) => TextEditingController(text: '0')).toList(),
        );
      });
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

  void showSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // Texto sempre branco
        ),
        backgroundColor: isError
            ? Colors.red
            : Colors.green, // Vermelho para erro, verde para sucesso
        duration: const Duration(seconds: 3),
      ),
    );
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

    try {
      final Map<String, dynamic> requestBody = {
        'tipoProdutoId': 1,
        'produtoId': 1,
        'descricao': descricaoController.text,
        'listFotos': imageList,
        'qtdSacos': int.tryParse(qtdSacosController.text) ?? 0,
        'vlrSacos': double.tryParse(vlrSacosController.text) ?? 0,
        'isCargaFechada': isCargaFechada,
        'tipoGrao': selectedTipoGrao,
        'dtRetirada': dtRetirada?.toIso8601String(),
        'parceiro': {'id': AuthUtility.userInfo?.data?.id},
        'status': 'A',
        'qtdsacosoriginal': int.tryParse(qtdSacosController.text) ?? 0,
        'classificacao': classificacaoList,
        if (useCustomAddress) 'enderecoRetirada': customAddress,
      };

      // Faz a chamada à API
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.insertProduto, requestBody);

      // Navigator.of(context).pop(); // Fecha o loader

      // Verifica o resultado da requisição
      if (response.isSuccess) {
        showSnackBar(
          message: "Venda enviada com sucesso!",
          isError: false,
        );
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
        showSnackBar(
          message: "Erro ao enviar proposta.",
          isError: true,
        );
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dtRetirada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != dtRetirada) {
      setState(() {
        dtRetirada = picked;
        dtRetiradaController.text =
            DateFormat('dd/MM/yyyy', 'pt_BR').format(picked);
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
      backgroundColor: lightGreenBackground,
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
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Data para Retirada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    locale: const Locale(
                                        'pt', 'BR'), // Idioma em português
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      dtRetirada = pickedDate;
                                    });
                                  }
                                },
                                child: Text(
                                  dtRetirada == null
                                      ? 'Data para Retirada'
                                      : DateFormat('dd/MM/yyyy', 'pt_BR')
                                          .format(dtRetirada!),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedTipoProduto,
                          decoration: customInputDecoration('Tipo de Produto'),
                          items: ['Arroz em Casca', 'Arroz Esbramado']
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
                        DropdownButtonFormField<String>(
                          value: selectedTipoGrao,
                          decoration: customInputDecoration('Tipo de Grão'),
                          items: ['Verde', 'Seco']
                              .map((tipo) => DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTipoGrao = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: pickImages,
                          icon: const Icon(Icons.photo),
                          label: const Text("Adicionar Fotos"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
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
