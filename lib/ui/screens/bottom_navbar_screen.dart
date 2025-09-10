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
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample screens for demonstration
  final List<Widget> _screens = [
    const Center(
      child: Text('Notícias Screen', style: TextStyle(fontSize: 24)),
    ),
    const Center(child: Text('Cotação Screen', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Comprar Screen', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Vender Screen', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Perfil Screen', style: TextStyle(fontSize: 24))),
  ];

  final List<SidebarItem> _sidebarItems = [
    SidebarItem(icon: FontAwesomeIcons.newspaper, label: "Notícias"),
    SidebarItem(icon: FontAwesomeIcons.chartLine, label: "Cotação"),
    SidebarItem(icon: FontAwesomeIcons.cartShopping, label: "Comprar"),
    SidebarItem(icon: FontAwesomeIcons.tags, label: "Vender"),
    SidebarItem(icon: FontAwesomeIcons.user, label: "Perfil"),
  ];

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
              color: Colors.green[50],
              border: Border(right: BorderSide(color: Colors.green[100]!)),
            ),
            child: Column(
              children: [
                // App Logo/Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  child: _isSidebarCollapsed
                      ? const Icon(
                          FontAwesomeIcons.layerGroup,
                          size: 30,
                          color: Colors.green,
                        )
                      : const Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.layerGroup,
                              size: 30,
                              color: Colors.green,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Task Manager",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
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
