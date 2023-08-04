import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/task_card.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class CancelledTaskScreen extends StatefulWidget {
  const CancelledTaskScreen({super.key});

  @override
  State<CancelledTaskScreen> createState() => _CancelledTaskScreenState();
}

class _CancelledTaskScreenState extends State<CancelledTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCancelledTaskFunction();
    });
  }

  TaskListModel _cancelledTaskModel = TaskListModel();
  bool _loadingScreenForCancelledTaskScreen = false;

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
      _cancelledTaskModel.data!.removeWhere((element) => element.sId == taskId);
    }
  }

  Future<void> getCancelledTaskFunction() async {
    _loadingScreenForCancelledTaskScreen = true;
    if (mounted) {
      setState(() {});
    }

    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.cancelledTaskStatus);
    if (response.isSuccess) {
      _cancelledTaskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data"),
          ),
        );
      }
    }
    _loadingScreenForCancelledTaskScreen = false;
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
                  getCancelledTaskFunction();
                },
                child: _loadingScreenForCancelledTaskScreen
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemBuilder: (context, int index) {
                          return CustomTaskCard(
                            title: _cancelledTaskModel.data?[index].title ??
                                "unknown",
                            description:
                                _cancelledTaskModel.data?[index].description ??
                                    "",
                            createdDate:
                                _cancelledTaskModel.data?[index].createdDate ??
                                    "",
                            status: _cancelledTaskModel.data?[index].status ??
                                "New",
                            onEditPressed: () {},
                            onDeletePressed: () {
                              deleteTask(_cancelledTaskModel.data![index].sId!);
                            },
                            chipColor: Colors.red,
                            onChangeStatusPressed: () {
                              statusUpdateButtomSheet(
                                  _cancelledTaskModel.data![index]);
                            },
                          );
                        },
                        itemCount: _cancelledTaskModel.data?.length ?? 0),
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
              getCancelledTaskFunction();
            },
          );
        });
  }
}
