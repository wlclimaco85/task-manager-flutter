import 'package:flutter/material.dart';
import 'package:task_manager_flutter/web/screens/splash_screens.dart';

void main() {
  runApp(const TaskManagerWebApp());
}

class TaskManagerWebApp extends StatelessWidget {
  const TaskManagerWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager Web',
      home: WebSplashScreen(),
    );
  }
}
