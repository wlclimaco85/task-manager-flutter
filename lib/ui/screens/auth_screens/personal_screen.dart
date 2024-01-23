import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/custom_button.dart';
import 'package:task_manager_flutter/ui/widgets/itens_list_personal.dart';
import 'package:task_manager_flutter/ui/widgets/custom_password_text_field.dart';
import 'package:task_manager_flutter/ui/widgets/custom_text_form_field.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/data/models/personal_model.dart';
import 'package:task_manager_flutter/ui/widgets/input_field_busca.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _PersonalScreenState extends State<PersonalScreen> {
  @override
  void initState() {
    findAllPersonal();
    super.initState();
  }

  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => print(message);

  bool _addNewTaskLoading = false;

  Future<void> findAllPersonal() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Map<String, dynamic> requestBody = {
      "cref": '',
      "id": 1,
    };

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.allPersonal, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data['personalDto'];
        mywidgets = [];
        mywidgets.add(const InputBuscarField(
            hint: "Username", obscure: false, icon: Icons.person_outline));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensExample(
                  nome: element['codDadosPessoal']['nome'],
                  cpf: element['codDadosPessoal']['cpf'],
                  cref: element['cref'],
                  valor: element['vlrAula'],
                  foto: element['codDadosPessoal']['photo'],
                  id: element['id'],
                ),
              ],
            ),
          );
        }
        _isLoading = false;
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Task Added Failed"),
          ),
        );
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF340A9C),
      appBar: userBanner(
        context,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: mywidgets,
          ),
        ),
      ),
    );
  }
}
