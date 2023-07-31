// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/summery_count_model.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/update_profile.dart';

import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/summery_card.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

import 'add_task_screen.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      statusCount();
      getNewTasks();
    });
  }

  StatusCountModel statusCountModel = StatusCountModel();

  Future<void> statusCount() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.taskStatusCount);
    if (response.isSuccess) {
      statusCountModel = StatusCountModel.fromJson(response.body!);
    }
  }

  TaskListModel newTaskModel = TaskListModel();
  bool _loaderForNewTaskScreen = false;

  Future<void> getNewTasks() async {
    _loaderForNewTaskScreen = true;
    if (mounted) {
      setState(() {});
    }
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.newTaskStatus);
    if (response.isSuccess) {
      newTaskModel = TaskListModel.fromJson(response.body!);
    }
    _loaderForNewTaskScreen = false;
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
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: SummeryCard(numberOfTasks: 4, title: "New")),
                  Expanded(
                      child: SummeryCard(numberOfTasks: 4, title: "Completed")),
                  Expanded(
                      child: SummeryCard(numberOfTasks: 4, title: "Cancelled")),
                  Expanded(
                      child:
                          SummeryCard(numberOfTasks: 4, title: "In Progress")),
                ],
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  getNewTasks();
                },
                child: _loaderForNewTaskScreen
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView.builder(
                        itemCount: newTaskModel.data?.length ?? 0,
                        itemBuilder: (context, int index) {
                          return Card(
                            elevation: 4,
                            child: ListTile(
                                title: Text(newTaskModel.data?[index].title ??
                                    "Unknown"),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        newTaskModel.data?[index].description ??
                                            ""),
                                    Text(
                                        newTaskModel.data?[index].createdDate ??
                                            "unknown"),
                                    Row(
                                      children: [
                                        CustomChip(
                                          color: Colors.green,
                                          text: newTaskModel
                                                  .data?[index].status ??
                                              "New",
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () {},
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.red.shade300,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                          );
                        },
                      ),
              ),
            ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomChip extends StatelessWidget {
  const CustomChip({
    Key? key,
    required this.text,
    required this.color,
  }) : super(key: key);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
