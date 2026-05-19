
import 'package:flutter/material.dart';
import 'windows/screens/home_screen.dart';

void main() {
  runApp(const TaskManagerWindowsApp());
}

class TaskManagerWindowsApp extends StatelessWidget {
  const TaskManagerWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager Windows',
      home: WindowsHomeScreen(),
    );
  }
}
