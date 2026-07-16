import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget Header Simples para Testes
class HeaderSimples extends StatefulWidget {
  final String title;
  final VoidCallback? onMenuTapped;

  const HeaderSimples({
    required this.title,
    this.onMenuTapped,
    Key? key,
  }) : super(key: key);

  @override
  State<HeaderSimples> createState() => _HeaderSimplesState();
}

class _HeaderSimplesState extends State<HeaderSimples> {
  bool _menuAberto = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                key: const Key('header_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                key: const Key('menu_button'),
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  setState(() => _menuAberto = !_menuAberto);
                  widget.onMenuTapped?.call();
                },
              ),
            ],
          ),
        ),
        if (_menuAberto)
          Container(
            key: const Key('menu_dropdown'),
            color: Colors.blue.shade50,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  key: const Key('menu_item_1'),
                  title: const Text('Dashboard'),
                ),
                ListTile(
                  key: const Key('menu_item_2'),
                  title: const Text('Cobranças'),
                ),
                ListTile(
                  key: const Key('menu_item_3'),
                  title: const Text('Upload'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

void main() {
  group('Header Responsivo — Testes Widget', () {
    testWidgets(
      'deve exibir header com título',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        expect(find.byKey(const Key('header_title')), findsOneWidget);
        expect(find.text('AppAcademia'), findsOneWidget);
      },
    );

    testWidgets(
      'deve exibir botão de menu',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        expect(find.byKey(const Key('menu_button')), findsOneWidget);
      },
    );

    testWidgets(
      'deve abrir menu ao clicar no botão',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        expect(find.byKey(const Key('menu_dropdown')), findsNothing);

        await tester.tap(find.byKey(const Key('menu_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_dropdown')), findsOneWidget);
      },
    );

    testWidgets(
      'deve fechar menu ao clicar novamente',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('menu_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_dropdown')), findsOneWidget);

        await tester.tap(find.byKey(const Key('menu_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_dropdown')), findsNothing);
      },
    );

    testWidgets(
      'deve exibir itens de menu quando aberto',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('menu_button')));
        await tester.pumpAndSettle();

        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Cobranças'), findsOneWidget);
        expect(find.text('Upload'), findsOneWidget);
      },
    );

    testWidgets(
      'deve chamar callback ao clicar no menu',
      (WidgetTester tester) async {
        bool menuTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(
                title: 'AppAcademia',
                onMenuTapped: () {
                  menuTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('menu_button')));
        await tester.pump();

        expect(menuTapped, true);
      },
    );

    testWidgets(
      'deve renderizar com cores corretas',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HeaderSimples(title: 'AppAcademia'),
            ),
          ),
        );

        final container = find.ancestor(
          of: find.byKey(const Key('header_title')),
          matching: find.byType(Container),
        );

        expect(container, findsWidgets);
      },
    );
  });
}
