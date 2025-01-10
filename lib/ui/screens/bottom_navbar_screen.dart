import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/ui/screens/cotacao_grafico_screen.dart';
import 'package:task_manager_flutter/ui/screens/vendas_screen.dart';
import 'package:task_manager_flutter/ui/screens/negociacao_screen.dart';
import 'package:task_manager_flutter/ui/screens/progress_task_screen.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_compras_screen.dart';
import 'package:task_manager_flutter/ui/screens/carrinho_vendas_screen.dart';
import 'package:task_manager_flutter/ui/screens/product_register_screen.dart';
import 'package:task_manager_flutter/data/utils/api_links.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';

// Define theme colors
const Color lightGreenBackground = Color.fromARGB(255, 231, 247, 233);
const Color darkGreenBorder = Color.fromARGB(255, 1, 247, 14);

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;
  final List<Widget> screens = [
    const ProgressTaskScreen(),
    const CotacaoScreen(),
    const ProductCatalog(),
    const ProductRegisterScreen(),
  ];

  void onMenuOptionSelected(String option) {
    switch (option) {
      case "Itens Comprados":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductCatalogPageCompras(
              title: 'Produtos Comprados',
              apiUrl:
                  '${ApiLinks.vendedorFindByUser}${AuthUtility.userInfo?.data?.id}',
              actionIcon: Icons.edit,
              actionTooltip: 'Editar Produto',
            ),
          ),
        );
        break;
      case "Itens a Venda":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductCatalogPageVendas(
              title: 'Produtos do Vendedor',
              apiUrl:
                  '${ApiLinks.vendedorFindByUser}${AuthUtility.userInfo?.data?.id}',
              actionIcon: Icons.edit,
              actionTooltip: 'Editar Produto',
            ),
          ),
        );
        break;
      case "Itens em Negociação":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NegociacaoCatalogPage(
              title: 'Negociação',
              apiUrl:
                  '${ApiLinks.negociacaoFindByUser}${AuthUtility.userInfo?.data?.id}',
              actionIcon: Icons.edit,
              actionTooltip: 'Editar Produto',
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
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: lightGreenBackground,
          border: Border(
            top: BorderSide(color: darkGreenBorder, width: 2),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: lightGreenBackground,
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
          items: const [
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.newspaper), label: "Notícias"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.chartLine), label: "Cotação"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.cartShopping), label: "Comprar"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.tags), label: "Vender"),
            BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.bars), label: "Menu"),
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
      backgroundColor: lightGreenBackground,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FontAwesomeIcons.shoppingBag),
              title: const Text('Itens Comprados'),
              onTap: () => onMenuOptionSelected('Itens Comprados'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.store),
              title: const Text('Itens a Venda'),
              onTap: () => onMenuOptionSelected('Itens a Venda'),
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.handshake),
              title: const Text('Itens em Negociação'),
              onTap: () => onMenuOptionSelected('Itens em Negociação'),
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
