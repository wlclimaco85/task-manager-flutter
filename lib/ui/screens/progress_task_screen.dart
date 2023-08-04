import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:task_manager_flutter/ui/widgets/task_card.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class ProgressTaskScreen extends StatefulWidget {
  const ProgressTaskScreen({super.key});

  @override
  State<ProgressTaskScreen> createState() => _ProgressTaskScreenState();
}

class _ProgressTaskScreenState extends State<ProgressTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getInProgressTaskFunction();
    });
  }

  TaskListModel _inProgressTaskModel = TaskListModel();
  bool _loaderForInProgressTaskScreen = false;

  bool isLoadingForDeleteTask = false;

  Future<void> deleteTask(String taskId) async {
    isLoadingForDeleteTask = true;
    if (mounted) {
      setState(() {});
    }
    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.deleteTask(taskId));
    isLoadingForDeleteTask = false;
    if (mounted) {
      setState(() {});
    }
    if (response.isSuccess) {
      _inProgressTaskModel.data!
          .removeWhere((element) => element.sId == taskId);
    }
  }

  Future<void> getInProgressTaskFunction() async {
    _loaderForInProgressTaskScreen = true;
    if (mounted) {
      setState(() {});
    }

    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.inProgressTaskStatus);
    if (response.isSuccess) {
      _inProgressTaskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data"),
          ),
        );
      }
    }
    _loaderForInProgressTaskScreen = false;
    if (mounted) {
      setState(() {});
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
      body: ScreenBackground(
        child: Column(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  getInProgressTaskFunction();
                },
                child: _loaderForInProgressTaskScreen
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemBuilder: (context, int index) {
                          return CustomTaskCard(
                            title: _inProgressTaskModel.data?[index].title ??
                                "unknown",
                            description:
                                _inProgressTaskModel.data?[index].description ??
                                    "",
                            createdDate:
                                _inProgressTaskModel.data?[index].createdDate ??
                                    "",
                            status: _inProgressTaskModel.data?[index].status ??
                                "New",
                            onEditPressed: () {},
                            onDeletePressed: () {
                              deleteTask(
                                  _inProgressTaskModel.data![index].sId!);
                            },
                            chipColor: Colors.pink.shade400,
                            onChangeStatusPressed: () {statusUpdateButtomSheet( _inProgressTaskModel.data![index]);},
                          );
                        },
                        itemCount: _inProgressTaskModel.data?.length ?? 0),
              ),
            ))
          ],
        ),
      ),
    );
  }

  void statusUpdateButtomSheet(TaskData task) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return UpdateStatus(
            task: task,
            onTaskComplete: () {
              getInProgressTaskFunction();
            },
          );
        });
  }
}
