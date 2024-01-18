// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/summery_count_model.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/add_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/personal_screen.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:task_manager_flutter/ui/widgets/summery_card.dart';
import 'package:task_manager_flutter/ui/widgets/task_card.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';
import 'package:task_manager_flutter/ui/widgets/custom_menu_item.dart';
import 'package:task_manager_flutter/ui/screens/task_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';
import 'package:flutter/src/widgets/navigator.dart';

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
    final NetworkResponse newTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.newTaskStatus);
    TaskListModel newTaskModel = TaskListModel.fromJson((newTaskResponse != null
        ? newTaskResponse.body != null
            ? newTaskResponse.body!
            : {}
        : {}));

    if (mounted) {
      setState(() {
        count1 = newTaskModel.data?.length ?? 0;
      });
    }

    final cancelledTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.cancelledTaskStatus);
    TaskListModel cancelledTaskModel =
        TaskListModel.fromJson(cancelledTaskResponse != null
            ? cancelledTaskResponse.body != null
                ? cancelledTaskResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count2 = cancelledTaskModel.data?.length ?? 0;
      });
    }

    final completedTaskResponse =
        await NetworkCaller().getRequest(ApiLinks.completedTaskStatus);

    TaskListModel completedTaskModel =
        TaskListModel.fromJson(completedTaskResponse != null
            ? completedTaskResponse.body != null
                ? completedTaskResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count3 = completedTaskModel.data?.length ?? 0;
      });
    }

    final inProgressResponse =
        await NetworkCaller().getRequest(ApiLinks.inProgressTaskStatus);
    TaskListModel inProgressTaskModel =
        TaskListModel.fromJson(inProgressResponse != null
            ? inProgressResponse.body != null
                ? inProgressResponse.body!
                : {}
            : {});
    if (mounted) {
      setState(() {
        count4 = inProgressTaskModel.data?.length ?? 0;
      });
    }

    isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.deleteTask(taskId));
    if (response.isSuccess) {
      _taskModel.data!.removeWhere((element) => element.sId == taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task Deleted Successfully!")));
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Personal',
                color: 'Screenshot_2.png',
                onPresse: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PersonalScreen()));
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Academias',
                color: 'images (1).png',
                onPresse: () {
                  print('Academias');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Treinos',
                color: 'images.png',
                onPresse: () {
                  print('Treinos');
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Suplemento',
                color: 'images (2).png',
                onPresse: () {
                  print('Suplemento');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Exames',
                color: 'images (3).png',
                onPresse: () {
                  print('Exames');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Dieta',
                color: 'images (4).png',
                onPresse: () {
                  print('Dieta');
                },
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButtonExample(
                text: 'Medicamento',
                color: 'Screenshot_3.png',
                onPresse: () {
                  print('Medicamento');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Avaliação Fisica',
                color: 'Screenshot_4.png',
                onPresse: () {
                  print('Avaliação Fisica');
                },
              ),
              const SizedBox(width: 10),
              IconButtonExample(
                text: 'Pagamentos',
                color: 'Screenshot_5.png',
                onPresse: () {
                  print('Pagamentos');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getChipColor() {
    switch (widget.screenStatus) {
      case "New":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      case "In Progress":
        return Colors.pink.shade400;
      default:
        return Colors.grey;
    }
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
