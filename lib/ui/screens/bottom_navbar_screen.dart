import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/ui/screens/chatMenssageScreen.dart';
import 'package:task_manager_flutter/ui/screens/negociacao_screen.dart';
import 'package:task_manager_flutter/ui/screens/comunicado_screen.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_compras_screen.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_vendas_screen.dart';
import 'package:task_manager_flutter/ui/screens/product_register_screen.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/ui/screens/LoginPopup_screens.dart';
import 'package:task_manager_flutter/data/constants/custom_colors.dart';
import 'package:task_manager_flutter/ui/screens/chatMessageListScreen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Verifica se o usuário está logado
  final bool isLoggedIn =
      AuthUtility.userInfo.data?.id != null &&
      AuthUtility.userInfo.data!.id! > 1;

  // Obtém o nome do usuário ou retorna padrão
  String get userName {
    final user = AuthUtility.userInfo.data;
    if (user?.firstName != null && user?.lastName != null) {
      return '${user!.firstName!} ${user.lastName!}';
    } else if (user?.email != null) {
      return user!.email!;
    } else {
      return 'Usuário';
    }
  }

  // Obtém as telas com base no estado de login
  List<Widget> get _screens {
    return [
      ComunicadoScreen(
        apiLink: ApiLinks.allComunicados,
        screenStatus: 'In Progress',
      ),
      const ChatMessageScreen(
        sector: 'Financeiro',
        userName: 'Usuário',
        chatId: '0',
      ),
      isLoggedIn
          ? ChatListScreen(
              userName: AuthUtility.userInfo.data!.email ?? 'Usuário',
            )
          : const LoginPopup(),
      const ProductRegisterScreen(),
      isLoggedIn ? const ProductRegisterScreen() : const LoginPopup(),
    ];
  }

  // Itens da sidebar
  final List<SidebarItem> _sidebarItems = [
    SidebarItem(icon: FontAwesomeIcons.newspaper, label: "Notícias"),
    SidebarItem(icon: FontAwesomeIcons.chartLine, label: "Cotação"),
    SidebarItem(icon: FontAwesomeIcons.cartShopping, label: "Comprar"),
    SidebarItem(icon: FontAwesomeIcons.tags, label: "Vender"),
    SidebarItem(icon: FontAwesomeIcons.user, label: "Perfil"),
  ];

  // Função para logout
  void _handleLogout() {
    // Implementar lógica de logout aqui
    AuthUtility.clearUserInfo();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPopup()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: _isSidebarCollapsed ? 70 : 250,
            height: double.infinity,
            decoration: BoxDecoration(
              color: CustomColors().getLightGreenBackground(),
              border: Border(
                right: BorderSide(
                  color: CustomColors().getDarkGreenBorder(),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header do usuário
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.green[100]!),
                    ),
                  ),
                  child: _isSidebarCollapsed
                      ? CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.green,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green,
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: _handleLogout,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.rightFromBracket,
                                    size: 14,
                                    color: Colors.green[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sair',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _sidebarItems.length,
                    itemBuilder: (context, index) {
                      final item = _sidebarItems[index];
                      return _SidebarListItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: _selectedIndex == index,
                        isCollapsed: _isSidebarCollapsed,
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),

                // Collapse/Expand Button
                Divider(height: 1, color: Colors.green[100]),
                ListTile(
                  leading: Icon(
                    _isSidebarCollapsed
                        ? FontAwesomeIcons.arrowRight
                        : FontAwesomeIcons.arrowLeft,
                    size: 18,
                    color: Colors.green[700],
                  ),
                  title: _isSidebarCollapsed
                      ? null
                      : Text(
                          _isSidebarCollapsed ? "Expandir" : "Recolher",
                          style: TextStyle(color: Colors.green[700]),
                        ),
                  onTap: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;

  SidebarItem({required this.icon, required this.label});
}

class _SidebarListItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarListItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.green[100] : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: isCollapsed
              ? Icon(
                  icon,
                  color: isSelected ? Colors.green[800] : Colors.grey[700],
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.green[800] : Colors.grey[700],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.green[800]
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
