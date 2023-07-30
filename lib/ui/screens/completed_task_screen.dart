import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({super.key});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
  TaskListModel _completedTaskModel = TaskListModel();

  Future<void> getAllCompletedTaskFunction() async {
    if (mounted) {
      setState(() {});
    }

    NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.completedTaskStatus);
    if (response.isSuccess) {
      _completedTaskModel = TaskListModel.fromJson(response.body!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load data"),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(context),
      body: ScreenBackground(
        child: Column(
          children: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                  itemBuilder: (context, int index) {
                    return Card(
                      elevation: 4,
                      child: ListTile(
                          title: Text(
                              _completedTaskModel.data?[index].title ?? ""),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_completedTaskModel
                                      .data?[index].description ??
                                  ""),
                              Text(_completedTaskModel
                                      .data?[index].createdDate ??
                                  ""),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      _completedTaskModel.data?[index].status ??
                                          "New",
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.green,
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
                  itemCount: _completedTaskModel.data?.length ?? 0),
            ))
          ],
        ),
      ),
    );
  }
}
