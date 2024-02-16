import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/home_fab.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/home_list_model.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/widgets/input_field_busca.dart';
import 'package:task_manager_flutter/ui/widgets/itens_list_academia.dart';
import 'package:task_manager_flutter/ui/widgets/academia_dynamic_form.dart';


class AcademiaScreen extends StatefulWidget {
  const AcademiaScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<AcademiaScreen> createState() => _AcademiaScreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _AcademiaScreenState extends State<AcademiaScreen> {
  @override
  void initState() {
    findAllAcademia();
    super.initState();
  }

  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => print(message);

  bool _addNewTaskLoading = false;

  Future<void> findAllAcademia() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Map<String, dynamic> requestBody = {
      "cref": '',
      "id": 1,
    };

    void onPressedss() => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AcademiaDynamicForm()));

    final NetworkResponse response =
        await NetworkCaller().postRequest(ApiLinks.allAcademia, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data['academiaDto'];
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Academia", obscure: false, icon: Icons.person_outline, onPresseds: onPressedss));
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
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Academia", obscure: false, icon: Icons.person_outline, onPresseds: onPressedss));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nenhuma academia cadastrada!"),
          ),
        );
        _isLoading = false;
      }
    }
  }

  List<HomeListModel> listModels = [
    HomeListModel(
      title: "Academia - O Club",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Biometa Academia",
      assetIcon: "assets/icons/gym_icon.png",
    ),
    HomeListModel(
      title: "Academia Titanium Core",
      assetIcon: "assets/icons/gym_icon.png",
    )
  ];
  refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    //  floatingActionButton: getHomeFab(context, listModels, refreshPage),
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
