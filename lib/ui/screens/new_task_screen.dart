// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/network_response.dart';
import 'package:task_manager_flutter/data/models/task_model.dart';
import 'package:task_manager_flutter/data/services/network_caller.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';

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
    getTasks("New");
    super.initState();
  }

  TaskModel newTaskModel = TaskModel();

  Future<void> getTasks(status) async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.listTaskByStatus(status));
    if (response.isSuccess) {
      newTaskModel = TaskModel.fromJson(jsonDecode("${response.body}"));
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: userBanner(context),
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
              child: ListView.builder(
                itemCount: newTaskModel.data?.length ?? 0,
                itemBuilder: (context, int index) {
                  return Card(
                    elevation: 4,
                    child: ListTile(
                        title: Text(newTaskModel.data?[index].title ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(newTaskModel.data?[index].description ?? ""),
                            Text(newTaskModel.data?[index].createdDate ??
                                "unknown"),
                            Row(
                              children: [
                                const CustomChip(
                                  color: Colors.green,
                                  text: 'New',
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
