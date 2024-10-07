import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/ui/screens/exames_screen.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/custom_menu_item.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/models/summery_count_model.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:task_manager_flutter/ui/screens/personal_screen.dart';
import 'package:task_manager_flutter/ui/screens/academia_screen.dart';
import 'package:task_manager_flutter/ui/screens/suplemento_screen.dart';
import 'package:task_manager_flutter/ui/screens/medicamento_screen.dart';
import 'package:task_manager_flutter/ui/screens/dieta_screen.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';

class TaskScreen extends StatefulWidget {
  final String screenStatus;
  final String apiLink;
  final bool showAllSummeryCard;
  final bool floatingActionButton;

  const TaskScreen({
    Key? key,
    required this.screenStatus,
    required this.apiLink,
    this.showAllSummeryCard = false,
    this.floatingActionButton = true,
  }) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  void initState() {
    super.initState();
  }

  TaskListModel _taskModel = TaskListModel();
  bool isLoading = false;

  Future<void> getTask() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response =
        await NetworkCaller().getRequest(widget.apiLink);
    if (response.isSuccess) {
      _taskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data!"),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  StatusCountModel statusCountModel = StatusCountModel();
  int count1 = 0;
  int count2 = 0;
  int count3 = 0;
  int count4 = 0;

  Future<void> statusCount() async {
    isLoading = true;
    if (mounted) {
      setState(() {});
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  // int getCountForStatus(String status) {
  //   final Data? statusData = statusCountModel.data?.firstWhere(
  //     (data) => data.statusId == status,
  //     orElse: () => Data(statusId: status, count: 0),
  //   );
  //   return statusData?.count ?? 0;
  // }
  bool standardSelected = false;
  bool filledSelected = false;
  bool tonalSelected = false;
  bool outlinedSelected = false;
  int count = 0;

  void log(String message) => print(message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors().getAppFundoPage(),
      appBar: userBanner(
        context,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Calendario',
                color: 'calendario.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PersonalScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Solicitações',
                color: 'solicitacao.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AcademiaScreen()));
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'GED',
                color: 'pngwing.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SuplementoScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Comunicados',
                color: 'anuncio.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ExameScreen()));
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Processos',
                color: 'processo.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Medicamentoscreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Dashboard',
                color: 'clipart998502.png',
                onPresse: () {
                  print('Avaliação Fisica');
                },
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }

  void statusUpdateButtomSheet(TaskData task) {
    showModalBottomSheet(
      shape: ShapeBorder.lerp(
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.black)),
          RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.black)),
          1)!,
      context: context,
      builder: (context) {
        return UpdateStatus(
          task: task,
          onTaskComplete: () {
            getTask();
          },
        );
      },
    );
  }
}
