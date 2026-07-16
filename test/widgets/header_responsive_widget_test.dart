import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Header Responsivo (Mobile/Web)
class HeaderResponsive extends StatefulWidget {
  final String title;
  final Function(String)? onMenuItemSelected;

  const HeaderResponsive({
    required this.title,
    this.onMenuItemSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<HeaderResponsive> createState() => _HeaderResponsiveState();
}

class _HeaderResponsiveState extends State<HeaderResponsive> {
  bool _isMobileMenuOpen = false;
  final List<String> _menuItems = [
    'Dashboard',
    'Cobrança',
    'Upload',
    'Configurações',
    'Sair',
  ];

  void _toggleMobileMenu() {
    setState(() {
      _isMobileMenuOpen = !_isMobileMenuOpen;
    });
  }

  void _onMenuItemTap(String item) {
    widget.onMenuItemSelected?.call(item);
    setState(() {
      _isMobileMenuOpen = false;
    });
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile(context)) {
      return _buildMobileHeader(context);
    } else {
      return _buildWebHeader(context);
    }
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  key: const Key('header_title_mobile'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const Key('menu_toggle_button'),
                icon: Icon(
                  _isMobileMenuOpen ? Icons.close : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: _toggleMobileMenu,
              ),
            ],
          ),
        ),
        if (_isMobileMenuOpen)
          Container(
            key: const Key('mobile_menu_drawer'),
            color: Colors.blue.shade50,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _menuItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return ListTile(
                  key: Key('menu_item_$item'),
                  title: Text(item),
                  onTap: () => _onMenuItemTap(item),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWebHeader(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            key: const Key('header_title_web'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: _menuItems.map((item) {
              return TextButton(
                key: Key('web_menu_item_$item'),
                onPressed: () => _onMenuItemTap(item),
                child: Text(
                  item,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Header Responsivo — Testes Widget', () {
    testWidgets(
      'header deve exibir menu lateral em mobile',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'AppAcademia',
              ),
            ),
          ),
        );

        // ACT — não tem menu aberto inicialmente
        expect(
          find.byKey(const Key('mobile_menu_drawer')),
          findsNothing,
        );

        // Toca no botão de menu
        await tester.tap(find.byKey(const Key('menu_toggle_button')));
        await tester.pumpAndSettle();

        // ASSERT
        expect(
          find.byKey(const Key('mobile_menu_drawer')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('menu_item_Dashboard')), findsOneWidget);
        expect(find.byKey(const Key('menu_item_Cobrança')), findsOneWidget);
        expect(find.byKey(const Key('menu_item_Upload')), findsOneWidget);
      },
    );

    testWidgets(
      'header deve exibir menu horizontal em web',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'AppAcademia',
              ),
            ),
          ),
        );

        // ASSERT
        expect(find.byKey(const Key('header_title_web')), findsOneWidget);
        expect(find.byKey(const Key('web_menu_item_Dashboard')), findsOneWidget);
        expect(find.byKey(const Key('web_menu_item_Cobrança')), findsOneWidget);
        expect(find.byKey(const Key('web_menu_item_Upload')), findsOneWidget);
      },
    );

    testWidgets(
      'deve recolapsar menu quando item é clicado',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        bool itemSelecionado = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'AppAcademia',
                onMenuItemSelected: (item) {
                  itemSelecionado = (item == 'Dashboard');
                },
              ),
            ),
          ),
        );

        // ACT
        await tester.tap(find.byKey(const Key('menu_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile_menu_drawer')), findsOneWidget);

        await tester.tap(find.byKey(const Key('menu_item_Dashboard')));
        await tester.pumpAndSettle();

        // ASSERT
        expect(find.byKey(const Key('mobile_menu_drawer')), findsNothing);
        expect(itemSelecionado, true);
      },
    );

    testWidgets(
      'deve fechar menu ao clicar no ícone de fechar',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'AppAcademia',
              ),
            ),
          ),
        );

        // ACT — abrir menu
        await tester.tap(find.byKey(const Key('menu_toggle_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('mobile_menu_drawer')), findsOneWidget);

        // Fechar menu
        await tester.tap(find.byKey(const Key('menu_toggle_button')));
        await tester.pumpAndSettle();

        // ASSERT
        expect(find.byKey(const Key('mobile_menu_drawer')), findsNothing);
      },
    );

    testWidgets(
      'deve renderizar título correto em mobile',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'Teste Mobile',
              ),
            ),
          ),
        );

        // ASSERT
        expect(find.text('Teste Mobile'), findsOneWidget);
        expect(find.byKey(const Key('header_title_mobile')), findsOneWidget);
      },
    );

    testWidgets(
      'deve renderizar título correto em web',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'Teste Web',
              ),
            ),
          ),
        );

        // ASSERT
        expect(find.text('Teste Web'), findsOneWidget);
        expect(find.byKey(const Key('header_title_web')), findsOneWidget);
      },
    );

    testWidgets(
      'deve notificar callback quando item web é clicado',
      (WidgetTester tester) async {
        // ARRANGE
        await tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

        String itemSelecionado = '';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderResponsive(
                title: 'AppAcademia',
                onMenuItemSelected: (item) {
                  itemSelecionado = item;
                },
              ),
            ),
          ),
        );

        // ACT
        await tester.tap(find.byKey(const Key('web_menu_item_Cobrança')));
        await tester.pumpAndSettle();

        // ASSERT
        expect(itemSelecionado, 'Cobrança');
      },
    );
  });
}
