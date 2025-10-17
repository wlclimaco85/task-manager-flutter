import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/chamado_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/chamado_grid_screen_dynamic.dart';
import 'package:task_manager_flutter/ui/screens/chatMessageListScreen.dart';
import 'package:task_manager_flutter/ui/screens/comunicado_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_pagar_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_receber_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_screen.dart';
import 'package:task_manager_flutter/ui/screens/documento_screen.dart';
import 'package:task_manager_flutter/ui/screens/file_upload_screen.dart';
import 'package:task_manager_flutter/ui/screens/parceiro_grid_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;

  List<Widget> get screens {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        AuthUtility.userInfo!.data!.id! > 1;

    return [
      const CalendarScreen(),
      AuthUtility.userInfo?.login?.email != null
          ? ChatListScreen(userName: AuthUtility.userInfo?.login?.email ?? '')
          : const ChatListScreen(userName: 'Usuário'),
      const ComunicadoScreen(),
      ChamadoGridScreen(hasPermission: (action) => true),
      const FileManagerScreen(),
      // Tela placeholder para o item "Mais" - não será mostrada pois o item abre um menu
      Container(),
    ];
  }

  void onMenuOptionSelected(String option) {
    switch (option) {
      case "Contas Pagar":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ContaPagarGridScreen(hasPermission: (action) => true)),
        );
        break;
      case "Contas Receber":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ContaReceberGridScreen(hasPermission: (action) => true)),
        );
        break;
      case "Parceiros":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ParceiroGridScreen(hasPermission: (action) => true)),
        );
        break;
      case "Dashboard":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        break;
      case "Teste":
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ChamadosScreenDinamic()));
        break;
      case "Sair":
        Navigator.pop(context);
        break;
      case "Voltar":
        Navigator.pop(context); // Fecha o menu
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        AuthUtility.userInfo!.data!.id! > 1;

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors().getLightGreenBackground(),
          border: Border(
            top: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: CustomColors().getLightGreenBackground(),
          currentIndex: selectedIndex,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          selectedItemColor: Colors.green,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            if (index == 5) {
              // Agora o índice 5 é o item "Mais"
              _showMenuOptions(context);
            } else {
              setState(() {
                selectedIndex = index;
              });
            }
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: "Calendario"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.chat), label: "Chat"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.campaign), label: "Comunicados"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.support_agent), label: "Solicitações"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.folder_open), label: "GED"),
            BottomNavigationBarItem(
                icon: Icon(isLoggedIn ? Icons.more_horiz : Icons.login),
                label: "Mais"),
          ],
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: CustomColors().getLightGreenBackground(),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Contas Pagar'),
              onTap: () => onMenuOptionSelected('Contas Pagar'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Contas Receber'),
              onTap: () => onMenuOptionSelected('Contas Receber'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Parceiros'),
              onTap: () => onMenuOptionSelected('Parceiros'),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Dashboard'),
              onTap: () => onMenuOptionSelected('Dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.text_increase_rounded),
              title: const Text('teste'),
              onTap: () => onMenuOptionSelected('Teste'),
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Sair'),
              onTap: () => onMenuOptionSelected('Sair'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Voltar'),
              onTap: () => onMenuOptionSelected('Voltar'),
            ),
          ],
        );
      },
    );
  }
}
