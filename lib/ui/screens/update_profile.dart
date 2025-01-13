import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import '../../data/models/login_model.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define as cores no início do documento
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color darkGreenBorder = Color.fromARGB(255, 230, 243, 231);

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  Data userInfo = AuthUtility.userInfo.data!;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _codProdutorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefone1Controller = TextEditingController();
  final TextEditingController _telefone2Controller = TextEditingController();
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _incrMunController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _fotoController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _signUpInProgress = false;

  XFile? pickImage;
  String? base64Image;
  File? image;
  bool _isSubmitting = false;

  //late List<XFile> = [];
  @override
  void initState() {
    super.initState();
    _emailController.text =
        AuthUtility.userInfo.data?.codDadosPessoal?.email ?? "";
    _nomeController.text =
        AuthUtility.userInfo.data?.codDadosPessoal?.nome ?? "";
    _cpfController.text = AuthUtility.userInfo.data?.codDadosPessoal?.cpf ?? "";
    _telefone1Controller.text = AuthUtility.userInfo.data?.mobile ?? "";
  }

  Future<XFile?> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return null;
    }
    final XFile? files = response.file;
    if (files != null) {
      final XFile? photo = pickImage;
      return files;
    } else {
      print(response.exception);
    }
    return null;
  }

  Future<void> sendProfileData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // Convert image to base64 if selected
    if (pickImage != null) {
      final bytes = await File(pickImage!.path).readAsBytes();
      base64Image = base64Encode(bytes);
    }

    Map<String, dynamic> requestBody = {
      "nome": _nomeController.text.trim(),
      "cpf": _cpfController.text.trim(),
      "codProdutor": _codProdutorController.text.trim(),
      "email": _emailController.text.trim(),
      "telefone1": _telefone1Controller.text.trim(),
      "telefone2": _telefone2Controller.text.trim(),
      "razaoSocial": _razaoSocialController.text.trim(),
      "incrMun": _incrMunController.text.trim(),
      "status": _statusController.text.trim(),
      "foto": base64Image ?? "",
      "endereco": {
        "rua": _ruaController.text.trim(),
        "numero": _numeroController.text.trim(),
        "bairro": _bairroController.text.trim(),
        "cidade": _cidadeController.text.trim(),
        "estado": _estadoController.text.trim(),
        "cep": _cepController.text.trim(),
      },
      "senha": _senhaController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8088/boletobancos/api/parceiro/insert'),
        body: jsonEncode(requestBody),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile inserted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to insert profile: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBackground,
      appBar: AppBar(
        title: const Text("Update Profile"),
        backgroundColor: darkGreenBorder,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                hintText: "Nome",
                controller: _nomeController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Nome obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "CPF",
                controller: _cpfController,
                validator: (value) =>
                    value == null || value.isEmpty ? "CPF obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Email",
                controller: _emailController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Email obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Telefone",
                controller: _telefone1Controller,
                validator: (value) => value == null || value.isEmpty
                    ? "Telefone1 obrigatório"
                    : null,
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                hintText: "Telefone",
                controller: _telefone2Controller,
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                hintText: "Cod. Produtor",
                controller: _codProdutorController,
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                  hintText: "Razão Social", controller: _razaoSocialController),
              const SizedBox(
                height: 16,
              ),
              InkWell(
                onTap: () {
                  imagePicked();
                },
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text("Photos"),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3F1D9D),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        pickImage?.name ?? "",
                        maxLines: 1,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                hintText: "Inscr. Municipal",
                controller: _incrMunController,
              ),
              const SizedBox(
                height: 16,
              ),
              CustomTextFormField(
                hintText: "CEP",
                controller: _cepController,
                validator: (value) =>
                    value == null || value.isEmpty ? "CEP obrigatório" : null,
              ),
              CustomTextFormField(
                hintText: "Rua",
                controller: _ruaController,
                validator: (value) =>
                    value == null || value.isEmpty ? "Rua obrigatória" : null,
              ),
              CustomTextFormField(
                hintText: "Número",
                controller: _numeroController,
                validator: (value) => value == null || value.isEmpty
                    ? "Número obrigatório"
                    : null,
              ),
              CustomTextFormField(
                hintText: "Cidade",
                controller: _cidadeController,
                validator: (value) => value == null || value.isEmpty
                    ? "Cidade obrigatória"
                    : null,
              ),
              CustomTextFormField(
                hintText: "Estado",
                controller: _estadoController,
                validator: (value) => value == null || value.isEmpty
                    ? "Estado obrigatório"
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : sendProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreenBorder,
                ),
                child: _isSubmitting
                    ? const CupertinoActivityIndicator()
                    : const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void imagePicked() async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Pick Image From:'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.camera);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  leading: const Icon(Icons.camera),
                  title: const Text('Camera'),
                ),
                ListTile(
                  leading: const Icon(Icons.image),
                  onTap: () async {
                    pickImage = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickImage != null) {
                      setState(() {});
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } else {}
                  },
                  title: const Text('Gallery'),
                )
              ],
            ),
          );
        });
  }
}

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const CustomTextFormField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: darkGreenBorder, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: darkGreenBorder, width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: darkGreenBorder, width: 2.0),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
