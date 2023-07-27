import 'package:flutter/material.dart';
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
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          selectedItemColor: Colors.green,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            selectedIndex = index;
            if (mounted) {
              setState(() {});
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.fiber_new), label: "New"),
            BottomNavigationBarItem(
                icon: Icon(Icons.done_all_rounded), label: "Complete"),
            BottomNavigationBarItem(
                icon: Icon(Icons.cancel_presentation_outlined),
                label: "Cancelled"),
            BottomNavigationBarItem(
                icon: Icon(Icons.whatshot_rounded), label: "Progress"),
          ]),
    );
  }
}
