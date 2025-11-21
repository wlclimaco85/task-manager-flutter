import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/chamado_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/chatMessageListScreen.dart';
import 'package:task_manager_flutter/ui/screens/comunicado_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_bancaria_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_pagar_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_receber_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/dashboard_screen.dart';
import 'package:task_manager_flutter/ui/screens/documento_screen.dart';
import 'package:task_manager_flutter/ui/screens/file_upload_screen.dart';
import 'package:task_manager_flutter/ui/screens/parceiro_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/ponto_screen.dart';

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
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
        break;
      case "Contas Bancarias":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ContaBancariaGridScreen(hasPermission: (action) => true),
          ),
        );
        break;
      case "Bater Ponto":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PontoScreen(),
          ),
        );
        break;
      case "Sair":
        Navigator.pop(context);
        break;
      case "Voltar":
        Navigator.pop(context);
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

  // ------------------------- MENU PREMIUM COMPLETO -------------------------------- //

  void _showMenuOptions(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "Menu",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: CustomColors().getLightGreenBackground(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -------- CABEÇALHO ESTILIZADO -------- //
                    Text(
                      "Mais Opções",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CustomColors().getDarkGreenBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: CustomColors().getDarkGreenBorder(),
                      thickness: 1.2,
                    ),
                    const SizedBox(height: 20),

                    // ---------------- GRID 3xN ---------------- //
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3, // <- você escolheu B (3 colunas)
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.85,
                      children: [
                        _menuItem(Icons.payments, "Contas Pagar"),
                        _menuItem(
                            Icons.account_balance_wallet, "Contas Receber"),
                        _menuItem(Icons.people, "Parceiros"),
                        _menuItem(Icons.bar_chart, "Dashboard"),
                        _menuItem(
                            Icons.text_increase_rounded, "Contas Bancarias"),
                        _menuItem(Icons.access_alarm_rounded, "Bater Ponto"),
                        _menuItem(Icons.exit_to_app, "Sair"),
                        _menuItem(Icons.arrow_back, "Voltar"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },

      // -------- ANIMAÇÃO SUAVE (SLIDE + FADE) -------- //
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(
            parent: anim,
            curve: Curves.fastOutSlowIn,
          )),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  // ----------------------- ITEM DO GRID ----------------------- //

  Widget _menuItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () => onMenuOptionSelected(title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomColors().getDarkGreenBorder().withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: CustomColors().getDarkGreenBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CustomColors().getDarkGreenBorder(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
