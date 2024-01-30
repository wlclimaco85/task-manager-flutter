import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/custom_text_form_field.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'home_list_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/custom_input_form.dart';
import 'package:task_manager_flutter/ui/widgets/custom_combo_box_form.dart';
import 'package:task_manager_flutter/ui/widgets/custom_combo_box_form_2.dart';
import 'package:task_manager_flutter/data/utils/personal_validation.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show utf8;
import 'dart:io' as io;
import 'package:dropdown_button2/dropdown_button2.dart';

class HomeModalAdd extends StatefulWidget {
  HomeModalAdd({super.key});
  @override
  State<HomeModalAdd> createState() => _HomeModalAddState();
}

class _HomeModalAddState extends State<HomeModalAdd> {
  final TextEditingController _nameController = TextEditingController();

  late GlobalKey<FormState> _formKey;
  late FocusNode _focusNode;
  XFile? pickImage;
  String? base64Image;
  bool _signUpInProgress = false;
  // List of items in our dropdown menu
  var sexo = [
    'Masculino',
    'Feminino',
  ];

  var dias = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo',
  ];
  List<String> sexoSelectedItems = [];

  List<String> diasSelectedItems = [];

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _numCPFController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _numCREFController = TextEditingController();
  final TextEditingController _vlrAulaController = TextEditingController();

  Future<List<int>> getLostData() async {
    final ImagePicker picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    final XFile? files = response.file;
    final XFile? photo;
    if (files != null) {
      photo = await pickImage;
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

    for (var element in sexoSelectedItems) {}
    Map<String, dynamic> requestBody = {
      "cref": _numCREFController.text.trim(),
      "vlrAula": _vlrAulaController.text.trim(),
      "codDadosPessoal": {
        "nome": _nomeController.text.trim(),
        "cpf": _numCPFController.text.trim(),
        "telefone1": _telefoneController.text.trim(),
        "email": _emailController.text.trim(),
        "tipoAluno": 2,
        "photo": "data:image/png;base64," + base64Imagess,
        "sexo": sexoSelectedItems.join(', ').toString(),
        "diaSemana": diasSelectedItems.join(', ').toString()
      }
    };

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.insertPersonal, requestBody);
    _signUpInProgress = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Successful"),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile update Failed"),
          ),
        );
      }
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
                  ),
                  CustomInputForm(
                      validator: EmailValidator.validate,
                      focusNode: _focusNode,
                      type: TextInputType.number,
                      keyField: "Email",
                      controller: _emailController),
                  CustomInputForm(
                      validator: EmailValidator.validate,
                      focusNode: _focusNode,
                      type: TextInputType.number,
                      keyField: "CPF",
                      controller: _numCPFController),
                  CustomInputForm(
                      validator: EmailValidator.validate,
                      focusNode: _focusNode,
                      type: TextInputType.number,
                      keyField: "Telefone",
                      controller: _telefoneController),
                  CustomInputForm(
                      validator: EmailValidator.validate,
                      focusNode: _focusNode,
                      type: TextInputType.number,
                      keyField: "Numero CREF",
                      controller: _numCREFController),
                  CustomInputForm(
                      validator: EmailValidator.validate,
                      focusNode: _focusNode,
                      type: TextInputType.number,
                      keyField: "Vlr Aula",
                      controller: _vlrAulaController),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Escolha o sexo atendimento',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              items: dias.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  //disable default onTap to avoid closing menu when selecting an item
                                  enabled: false,
                                  child: StatefulBuilder(
                                    builder: (context, menuSetState) {
                                      final isSelected =
                                          diasSelectedItems.contains(item);
                                      return InkWell(
                                        onTap: () {
                                          isSelected
                                              ? diasSelectedItems.remove(item)
                                              : diasSelectedItems.add(item);
                                          //This rebuilds the StatefulWidget to update the button's text
                                          setState(() {});
                                          //This rebuilds the dropdownMenu Widget to update the check mark
                                          menuSetState(() {});
                                        },
                                        child: Container(
                                          height: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                const Icon(
                                                    Icons.check_box_outlined)
                                              else
                                                const Icon(Icons
                                                    .check_box_outline_blank),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                              //Use last selected item as the current value so if we've limited menu height, it scroll to last item.
                              value: diasSelectedItems.isEmpty
                                  ? null
                                  : diasSelectedItems.last,
                              onChanged: (value) {},
                              selectedItemBuilder: (context) {
                                return diasSelectedItems.map(
                                  (item) {
                                    return Container(
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        diasSelectedItems.join(', '),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    );
                                  },
                                ).toList();
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 50,
                                width: 160,
                                padding:
                                    const EdgeInsets.only(left: 14, right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black26,
                                  ),
                                  color: Colors.redAccent,
                                ),
                                elevation: 2,
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(
                                  Icons.arrow_forward_ios_outlined,
                                ),
                                iconSize: 14,
                                iconEnabledColor: Colors.yellow,
                                iconDisabledColor: Colors.grey,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.redAccent,
                                ),
                                offset: const Offset(-20, 0),
                                scrollbarTheme: ScrollbarThemeData(
                                  radius: const Radius.circular(40),
                                  thickness: MaterialStateProperty.all(6),
                                  thumbVisibility:
                                      MaterialStateProperty.all(true),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                                padding: EdgeInsets.only(left: 14, right: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Select Items',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              items: sexo.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  //disable default onTap to avoid closing menu when selecting an item
                                  enabled: false,
                                  child: StatefulBuilder(
                                    builder: (context, menuSetState) {
                                      final isSelected =
                                          sexoSelectedItems.contains(item);
                                      return InkWell(
                                        onTap: () {
                                          isSelected
                                              ? sexoSelectedItems.remove(item)
                                              : sexoSelectedItems.add(item);
                                          //This rebuilds the StatefulWidget to update the button's text
                                          setState(() {});
                                          //This rebuilds the dropdownMenu Widget to update the check mark
                                          menuSetState(() {});
                                        },
                                        child: Container(
                                          height: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                const Icon(
                                                    Icons.check_box_outlined)
                                              else
                                                const Icon(Icons
                                                    .check_box_outline_blank),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  item,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                              //Use last selected item as the current value so if we've limited menu height, it scroll to last item.
                              value: sexoSelectedItems.isEmpty
                                  ? null
                                  : sexoSelectedItems.last,
                              onChanged: (value) {},
                              selectedItemBuilder: (context) {
                                return sexo.map(
                                  (item) {
                                    return Container(
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        sexoSelectedItems.join(', '),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    );
                                  },
                                ).toList();
                              },
                              buttonStyleData: ButtonStyleData(
                                height: 50,
                                width: 160,
                                padding:
                                    const EdgeInsets.only(left: 14, right: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black26,
                                  ),
                                  color: Colors.redAccent,
                                ),
                                elevation: 2,
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(
                                  Icons.arrow_forward_ios_outlined,
                                ),
                                iconSize: 14,
                                iconEnabledColor: Colors.yellow,
                                iconDisabledColor: Colors.grey,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                width: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.redAccent,
                                ),
                                offset: const Offset(-20, 0),
                                scrollbarTheme: ScrollbarThemeData(
                                  radius: const Radius.circular(40),
                                  thickness: MaterialStateProperty.all(6),
                                  thumbVisibility:
                                      MaterialStateProperty.all(true),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                height: 40,
                                padding: EdgeInsets.only(left: 14, right: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final _form = _formKey.currentState!;
          _form.validate();
          _focusNode.requestFocus();
          updateProfile();
        },
        child: Icon(Icons.check),
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
