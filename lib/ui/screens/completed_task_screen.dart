import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({super.key});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen> {
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
                          title: const Text("new task"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("description"),
                              const Text("due date"),
                              Row(
                                children: [
                                  const Chip(
                                    label: Text(
                                      "New",
                                      style: TextStyle(color: Colors.white),
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
                  itemCount: 20),
            ))
          ],
        ),
      ),
    );
  }
}
