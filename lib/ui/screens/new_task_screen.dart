import 'package:flutter/material.dart';
import 'package:task_manager_flutter/ui/widgets/screen_background.dart';
import 'package:task_manager_flutter/ui/widgets/summery_card.dart';
import 'package:task_manager_flutter/ui/widgets/user_banners.dart';

import 'add_task_screen.dart';

class NewTaskScreen extends StatelessWidget {
  
  const NewTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenBackground(
        child: Column(
          children: [
            const UserBanners(),
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
                                    backgroundColor: Colors.blue,
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
