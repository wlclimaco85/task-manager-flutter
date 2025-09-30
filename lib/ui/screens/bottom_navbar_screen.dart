import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_compras_screen.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_vendas_screen.dart';
import 'package:task_manager_flutter/ui/screens/chamado_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/chatMessageListScreen.dart';
import 'package:task_manager_flutter/ui/screens/comunicado_screen.dart';
import 'package:task_manager_flutter/ui/screens/documento_screen.dart';
import 'package:task_manager_flutter/ui/screens/file_upload_screen.dart';
import 'package:task_manager_flutter/ui/screens/negociacao_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_pagar_grid_screen.dart';
import 'package:task_manager_flutter/ui/screens/conta_receber_grid_screen.dart';

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
      CalendarScreen(),
      AuthUtility.userInfo?.data?.email != null
          ? ChatListScreen(userName: AuthUtility.userInfo?.data?.email ?? '')
          : const ChatListScreen(userName: 'Usuário'),
      ComunicadoScreen(
        apiLink: ApiLinks.allComunicados,
        screenStatus: 'In Progress',
      ),
      ChamadoGridScreen(hasPermission: (action) => true),
      FileUploadScreen(hasPermission: (perm) => true),
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
      case "Dashboard":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NegociacaoCatalogPage(
              title: 'Dashboard',
              apiUrl:
                  '${ApiLinks.negociacaoFindByUser}${AuthUtility.userInfo?.data?.id}',
              actionIcon: Icons.edit,
              actionTooltip: 'Dashboard',
            ),
          ),
        );
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
            if (index == 4) {
              _showMenuOptions(context);
            } else {
              setState(() {
                selectedIndex = index;
              });
            }
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.calendarPlus), label: "Calendario"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.chartLine), label: "Chat"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.prescription),
                label: "Comunicados"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.tags), label: "Solicitações"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.download), label: "GED"),
            BottomNavigationBarItem(
                icon: Icon(isLoggedIn
                    ? FontAwesomeIcons.bars
                    : FontAwesomeIcons.signInAlt),
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
              leading: const Icon(FontAwesomeIcons.shoppingBag),
              title: const Text('Contas Pagar'),
              onTap: () => onMenuOptionSelected('Contas Pagar'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.store),
              title: const Text('Contas Receber'),
              onTap: () => onMenuOptionSelected('Contas Receber'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.handshake),
              title: const Text('Dashboard'),
              onTap: () => onMenuOptionSelected('Dashboard'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.signOutAlt),
              title: const Text('Sair'),
              onTap: () => onMenuOptionSelected('Sair'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.arrowLeft),
              title: const Text('Voltar'),
              onTap: () => onMenuOptionSelected('Voltar'),
            ),
          ],
        );
      },
    );
  }
}
