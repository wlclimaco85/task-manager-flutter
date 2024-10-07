import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/ui/screens/cancelled_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/completed_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/new_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/progress_task_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;
  final List<Widget> screens = [
    const NewTaskScreen(),
    const CompleteTaskScreen(),
    const CancelledTaskScreen(),
    const ProgressTaskScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: screens[selectedIndex]);
  }
}
