import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/custom_input_form.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/personal_validation.dart';
import '../../data/models/login_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

class SuplementoModalAdd extends StatefulWidget {
  const SuplementoModalAdd({super.key});
  @override
  State<SuplementoModalAdd> createState() => _SuplementoModalAddState();
}

class _SuplementoModalAddState extends State<SuplementoModalAdd> {
  final TextEditingController _nameController = TextEditingController();

  late GlobalKey<FormState> _formKey;
  late FocusNode _focusNode;
  XFile? pickImage;
  String? base64Image;
  bool _signUpInProgress = false;

  @override
  void initState() {
    _formKey = GlobalKey<FormState>();
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _dataIniController = TextEditingController();
  final TextEditingController _dataFinController = TextEditingController();
  final TextEditingController _dataValController = TextEditingController();
  final TextEditingController _porcaoController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _saborController = TextEditingController();
  final TextEditingController _tamanhoController = TextEditingController();

  Future<List<int>> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    final XFile? files = response.file;
    final XFile? photo;
    if (files != null) {
      photo = pickImage;
      return files.readAsBytes();
    } else {
      const asciiDecoder = AsciiDecoder();
      final asciiValues = [104, 101, 108, 108, 111];
      return asciiValues;
      print(response.exception);
    }
  }

  Future<void> updateProfile() async {
    _signUpInProgress = true;
    if (mounted) {
      setState(() {});
    }
    String base64Imagess = "";
    if (pickImage != null) {
      // var bytes = File(pickImage!.path).readAsBytesSync();
      // String base64Image = base64Encode(bytes);
      print('upload proccess started');
      final bytess = io.File(pickImage!.path).readAsBytesSync();
      //  List<int> imageBytes = pickImage?.readAsBytesSync();
      // print(imageBytes);
      //String base64Images = base64Encode(imageBytes);
      base64Imagess = base64Encode(bytess);
    }
    Data userInfo = AuthUtility.userInfo.data!;

    Map<String, dynamic> af = {};
    af["id"] = userInfo.id;

    Map<String, dynamic> requestBody = {
      "codAluno": af,
      "nome": _nomeController.text.trim(),
      "marca": _marcaController.text.trim(),
      "dtInicio": _dataIniController.text.trim(),
      "dtFinal": _dataFinController.text.trim(),
      "dataVal": _dataValController.text.trim(),
      "tamanho": _tamanhoController.text.trim(),
      "dosagem": _porcaoController.text.trim(),
      "id": _idController.text.trim(),
      "valor": _valorController.text.trim(),
      "sabor": _saborController.text.trim(),
      "foto": "data:image/png;base64,$base64Imagess",
    };

    final NetworkResponse response = await NetworkCaller()
        .postRequest(ApiLinks.insertSuplemento, requestBody);
    _signUpInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Suplemento inserido com Success"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao inserir Suplemento"),
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _dataArray = []; //add this
  String? _data = ""; //add this
  void _onUpdate(int key, String value, chave) {
    void addData() {
      Map<String, dynamic> json = {
        'id': key,
        chave: value,
        chave: value,
        chave: value,
        chave: value
      };
      _dataArray.add(json);
      setState(() {
        _data = _dataArray.toString();
      });
    }

    if (_dataArray.isEmpty) {
      addData();
    } else {
      _dataArray.asMap().entries.map((entry) {
        if (entry.key == key && entry.value == chave) {
          _dataArray[key][chave] = value;
        }
        print(entry.key);
        print(entry.value);
      });

      for (var map in _dataArray) {
        if (map["id"] == key) {
          _dataArray[key][chave] = value;
          setState(() {
            _data = _dataArray.toString();
          });
          break;
        }
      }

      for (var map in _dataArray) {
        if (map["id"] == key) {
          return;
        }
      }
      addData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(context, onTapped: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UpdateProfileScreen()));
      }),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Container(
            alignment: Alignment.topCenter,
            color: CustomColors().getAppFundoPage(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Nome",
                    controller: _nomeController,
                    onPressed: (vale) => _onUpdate(0, "Nome", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Marca",
                    controller: _marcaController,
                    onPressed: (vale) => _onUpdate(0, "Marca", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Sabor",
                    controller: _saborController,
                    onPressed: (vale) => _onUpdate(0, "Sabor", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Tamanho",
                    controller: _tamanhoController,
                    onPressed: (vale) => _onUpdate(0, "Sabor", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data Começou a Tomar",
                    controller: _dataIniController,
                    onPressed: (vale) => _onUpdate(0, "TELEFONE", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data que acabou de Tomar",
                    controller: _dataFinController,
                    onPressed: (vale) => _onUpdate(0, "CREF", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data Validade",
                    controller: _dataValController,
                    onPressed: (vale) => _onUpdate(0, "VLRAULA", vale),
                  ),
                  InkWell(
                    onTap: () {
                      imagePicked();
                    },
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text("Foto"),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: CustomColors().getAppFundoImput(),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            pickImage?.name ?? "",
                            maxLines: 1,
                            style: const TextStyle(
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Dosagem/Dia",
                    controller: _porcaoController,
                    onPressed: (vale) => _onUpdate(0, "PORCAO", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Valor",
                    controller: _valorController,
                    onPressed: (vale) => _onUpdate(0, "PORCAO", vale),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final form = _formKey.currentState!;
          form.validate();
          _focusNode.requestFocus();
          updateProfile();
        },
        child: const Icon(Icons.check),
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
