import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/ui/screens/cancelled_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/completed_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/cotacao_grafico_screen.dart';
import 'package:task_manager_flutter/ui/screens/progress_task_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;
  final List<Widget> screens = [
    CotacaoScreen(),
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
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.shekelSign), label: "Noticias"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.checkToSlot), label: "Cotação"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.circleXmark), label: "Comprar"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.barsProgress), label: "Vender"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.barsProgress), label: "Entrar"),
          ]),
    );
  }
}
