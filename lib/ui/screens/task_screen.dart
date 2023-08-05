// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/summery_count_model.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/add_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/status_change_botom_sheet.dart';
import 'package:task_manager_flutter/ui/widgets/summery_card.dart';
import 'package:task_manager_flutter/ui/widgets/task_card.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getTask();
      statusCount();
    });
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

  Future<void> statusCount() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.taskStatusCount);
    if (response.isSuccess) {
      setState(() {
        statusCountModel = StatusCountModel.fromJson(response.body!);
      });
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
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  int getCountForStatus(String status) {
    final Data? statusData = statusCountModel.data?.firstWhere(
      (data) => data.statusId == status,
      orElse: () => Data(statusId: status, count: 0),
    );
    return statusData?.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(
        context,
        onTapped: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const UpdateProfileScreen()));
        },
      ),
      body: ScreenBackground(
        child: Column(
          children: [
            if (widget.showAllSummeryCard)
              Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SummeryCard(
                          numberOfTasks: _taskModel.data
                                  ?.where((element) => element.status == "New")
                                  .length ??
                              0,
                          title: "New",
                        ),
                      ),
                      Expanded(
                        child: SummeryCard(
                          numberOfTasks: _taskModel.data
                                  ?.where(
                                      (element) => element.status == "Complete")
                                  .length ??
                              0,
                          title: "Completed",
                        ),
                      ),
                      Expanded(
                        child: SummeryCard(
                          numberOfTasks: _taskModel.data
                                  ?.where((element) =>
                                      element.status == "Cancelled")
                                  .length ??
                              0,
                          title: "Cancelled",
                        ),
                      ),
                      Expanded(
                        child: SummeryCard(
                          numberOfTasks: _taskModel.data
                                  ?.where(
                                      (element) => element.title == "Progress")
                                  .length ??
                              0,
                          title: "Progress",
                        ),
                      ),
                    ],
                  )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: RefreshIndicator(
                    onRefresh: () => getTask(),
                    child: Visibility(
                      visible: isLoading == false,
                      replacement: const Center(
                        child: CircularProgressIndicator(),
                      ),
                      child: ListView.builder(
                          itemCount: _taskModel.data?.length ?? 0,
                          itemBuilder: (context, int index) {
                            return CustomTaskCard(
                                title:
                                    _taskModel.data![index].title ?? "Unknown",
                                description:
                                    _taskModel.data![index].description ?? "",
                                createdDate:
                                    _taskModel.data![index].createdDate ?? "",
                                status: _taskModel.data![index].status ?? "NEW",
                                chipColor: _getChipColor(),
                                onChangeStatusPressed: () {
                                  statusUpdateButtomSheet(
                                      _taskModel.data![index]);
                                },
                                onEditPressed: () {},
                                onDeletePressed: () {
                                  deleteTask(_taskModel.data![index].sId!);
                                });
                          }),
                    )),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Visibility(
        visible: widget.floatingActionButton == true,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddTaskScreen()));
          },
          child: const Icon(Icons.add),
        ),
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
