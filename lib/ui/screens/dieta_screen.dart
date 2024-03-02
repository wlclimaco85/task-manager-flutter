import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/utils/fotos_util.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/ui/widgets/input_field_busca.dart';
import 'package:task_manager_flutter/ui/screens/Dieta_add.dart';
import 'package:task_manager_flutter/ui/screens/Dieta_list.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import '../../data/models/login_model.dart';

class Dietacreen extends StatefulWidget {
  const Dietacreen({
    Key? key,
  }) : super(key: key);

  @override
  State<Dietacreen> createState() => _DietacreenState();
}

final TextEditingController _taskNameController = TextEditingController();
final TextEditingController _taskDescriptionController =
    TextEditingController();
List<Widget> mywidgets = [];
bool _isLoading = false;

class _DietacreenState extends State<Dietacreen> {
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
  final List<String> modalidadeList = ['Musculação'];

  void log(String message) => print(message);

  bool _addNewTaskLoading = false;

  List<String> getList(List<dynamic> newMap) {
    late List<String> modList = [];
    for (var v in newMap) {
      Map<String, dynamic> request = v;
      modList.add(v['nome']);
    }

    return modList;
  }

  Future<void> findAllAcademia() async {
    _isLoading = true;
    _addNewTaskLoading = true;
    if (mounted) {
      setState(() {});
    }
    Data userInfo = AuthUtility.userInfo.data!;

    Map<String, dynamic> af = {};
    af["id"] = userInfo.id;
    Map<String, dynamic> requestBody = {
      "codAluno": {"id": 1},
    };

    void onPressedss() => Navigator.push(context,
        MaterialPageRoute(builder: (context) => const DietaModalAdd()));

    final NetworkResponse response = await NetworkCaller()
        .postRequest(ApiLinks.findByAlunoByDieta, requestBody);
    _addNewTaskLoading = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _taskNameController.clear();
      _taskDescriptionController.clear();
      if (mounted) {
        dynamic data = response.body?['data'];
        List<dynamic> datas = data;
        mywidgets = [];
        mywidgets.add(InputBuscarField(
            hint: "Buscar Dieta",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        for (var element in datas) {
          mywidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListItensDieta(
                  nutricionista: element['nutricionista'] ?? "",
                  objetivo: element['objetivo'] ?? "",
                  dtConsulta: element['dtConsulta'] ?? "",
                  descricao: element['descricao'] ?? "",
                  oQueAchou: element['oQueAchou'] ?? "",
                  dtInicio: element['dtInicio'] ?? "",
                  dtFinal: element['dtFinal'] ?? "",
                  nota: element['nota'] != null ? element['nota'] : 0,
                  foto: element['fotos'] != null
                      ? verificFoto(element['fotos'][0])
                      : getImagepadrao(),
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
            hint: "Buscar Dieta",
            obscure: false,
            icon: Icons.person_outline,
            onPresseds: onPressedss));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nenhuma suplemento cadastrado!"),
          ),
        );
        _isLoading = false;
      }
    }
  }

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
