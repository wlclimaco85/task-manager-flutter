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
  int selectedIndex = 0;
  List<Widget> get screens {
    final isLoggedIn =
        AuthUtility.userInfo.data?.id != null &&
        AuthUtility.userInfo.data!.id! > 1;

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
      AuthUtility.userInfo.data?.email != null
          ? ChatListScreen(userName: AuthUtility.userInfo.data!.email!)
          : const ChatListScreen(userName: 'Usuário'),
      const ProductRegisterScreen(),
      isLoggedIn ? const ProductRegisterScreen() : const LoginPopup(),
    ];
  }

  void onMenuOptionSelected(String option) {
    switch (option) {
      case "Itens Comprados":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductCatalogPageCompras(
              title: 'Produtos Comprados',
              apiUrl:
                  '${ApiLinks.vendedorFindByUser}${AuthUtility.userInfo.data?.id}',
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
                  '${ApiLinks.vendedorFindByUser}${AuthUtility.userInfo.data?.id}',
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
                  '${ApiLinks.negociacaoFindByUser}${AuthUtility.userInfo.data?.id}',
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
    final isLoggedIn =
        AuthUtility.userInfo.data?.id != null &&
        AuthUtility.userInfo.data!.id! > 1;

    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors().getLightGreenBackground(),
          border: Border(
            top: BorderSide(
              color: CustomColors().getDarkGreenBorder(),
              width: 2,
            ),
          ),
        ),

        /*
        child: BottomNavigationBar(
          backgroundColor: lightGreenBackground,
          currentIndex: selectedIndex,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          selectedItemColor: Colors.green,
          showSelectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.newspaper), label: "Notícias"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.chartLine), label: "Cotação"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.cartShopping), label: "Comprar"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.tags), label: "Vender"),
            if (isLoggedIn)
              const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.bars),
                label: "Mais",
              )
            else
              const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.signInAlt),
                label: "Login",
              ),
            BottomNavigationBarItem(
              icon: Icon(isLoggedIn ? Icons.help_outline : Icons.help),
              label: "Ajuda",
            ),
          ],
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });

            // Lógica para navegação
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressTaskScreen(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CotacaoScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductCatalog(),
                  ),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductRegisterScreen(),
                  ),
                );
                break;
              case 4:
                if (!isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPopup(),
                    ),
                  );
                } else {
                  debugPrint("Botão 'Mais' pressionado");
                }
                break;
              case 5:
                debugPrint("Botão 'Ajuda' pressionado");
                break;
              default:
                debugPrint("Índice desconhecido: $index");
            }
          },
        ),
      ),
    );
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
          items: [
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.newspaper), label: "Notícias"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.chartLine), label: "Cotação"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.cartShopping), label: "Comprar"),
            const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.tags), label: "Vender"),
            if (AuthUtility.userInfo?.data?.id != null &&
                AuthUtility.userInfo!.data!.id! > 1)
              const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.bars),
                label: "Mais",
              )
            else
              const BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.signInAlt),
                label: "Login",
              ),
            const BottomNavigationBarItem(
              icon: if (AuthUtility.userInfo?.data?.id != null && AuthUtility.userInfo!.data!.id! > 1) 
                      Icon(Icons.help_outline),
                    else 
                      Icon(Icons.help),
                      
              label: "Ajuda",
            ),
          ],
          onTap: (index) {
            // Atualiza o índice selecionado
            setState(() {
              selectedIndex = index;
            });

            // Lógica para navegação com base no índice
            switch (index) {
              case 0: // Notícias
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgressTaskScreen(),
                  ),
                );
                break;
              case 1: // Cotação
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CotacaoScreen(),
                  ),
                );
                break;
              case 2: // Comprar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductCatalog(),
                  ),
                );
                break;
              case 3: // Vender
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductRegisterScreen(),
                  ),
                );
                break;
              case 4: // Mais ou Login
                if (AuthUtility.userInfo?.data?.id == null ||
                    AuthUtility.userInfo!.data!.id! <= 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPopup(),
                    ),
                  );
                } else {
                  debugPrint("Botão 'Mais' pressionado");
                }
                break;
              case 5: // Ajuda
                debugPrint("Botão 'Ajuda' pressionado");
                break;
              default:
                debugPrint("Índice desconhecido: $index");
            }
          },
        ), */
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
              icon: Icon(FontAwesomeIcons.newspaper),
              label: "Notícias",
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.chartLine),
              label: "Cotação",
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.cartShopping),
              label: "Comprar",
            ),
            const BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.tags),
              label: "Vender",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                isLoggedIn ? FontAwesomeIcons.bars : FontAwesomeIcons.signInAlt,
              ),
              label: (isLoggedIn ? "Mais" : 'Login'),
            ),
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
