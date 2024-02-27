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
import 'dart:io';
import 'package:task_manager_flutter/ui/widgets/custom_insert_list_foto.dart';

class ExamesModalAdd extends StatefulWidget {
  const ExamesModalAdd({super.key});
  @override
  State<ExamesModalAdd> createState() => _ExamesModalAddState();
}

class _ExamesModalAddState extends State<ExamesModalAdd> {
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

  final TextEditingController _nomeExController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _medicoIniController = TextEditingController();
  final TextEditingController _laboratorioController = TextEditingController();
  final TextEditingController _resultadoController = TextEditingController();
  final TextEditingController _dtExameController = TextEditingController();
  final TextEditingController _dtEntregaController = TextEditingController();

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

  Future<String?> uploadPdf(String fileName, File file) async {
    return null;
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
      "idaluno": af,
      "nome": _nomeExController.text.trim(),
      "descricao": _descricaoController.text.trim(),
      "medico": _medicoIniController.text.trim(),
      "laboratorio": _laboratorioController.text.trim(),
      "resultado": _resultadoController.text.trim(),
      "dtExame": _dtExameController.text.trim(),
      "dtEntregaResulExame": _dtEntregaController.text.trim(),
      // "foto": "data:image/png;base64,$base64Imagess",
    };

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.insertExame, requestBody);
    _signUpInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Exame inserido com Success"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao inserir Exame"),
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
                    keyField: "Nome Exame",
                    controller: _nomeExController,
                    onPressed: (vale) => _onUpdate(0, "Nome", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Nome Laboratorio",
                    controller: _laboratorioController,
                    onPressed: (vale) => _onUpdate(0, "laboratorio", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Descrição ('Porque do exame')",
                    controller: _descricaoController,
                    onPressed: (vale) => _onUpdate(0, "descricao", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField:
                        "Resultado do exame ('Conforme o medico dizer na consulta')",
                    controller: _resultadoController,
                    onPressed: (vale) => _onUpdate(0, "resultado", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data Exame",
                    controller: _dtExameController,
                    onPressed: (vale) => _onUpdate(0, "dtExame", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.datetime,
                    keyField: "Data Entrega Exame",
                    controller: _dtEntregaController,
                    onPressed: (vale) =>
                        _onUpdate(0, "dtEntregaResulExame", vale),
                  ),
                  CustomInputForm(
                    validator: EmailValidator.validate,
                    focusNode: _focusNode,
                    type: TextInputType.text,
                    keyField: "Medico Solicitante",
                    controller: _medicoIniController,
                    onPressed: (vale) => _onUpdate(0, "medico", vale),
                  ),
                  const ListFotoForm(),
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
