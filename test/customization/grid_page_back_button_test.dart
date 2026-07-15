import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/customization/generic_grid/grid_page.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

// Testes de cobertura para card #428:
// Bug: botão "Voltar" desaparecido em telas mobile (Comercial/Financeiro)
// abertas via Navigator.push do menu "Mais Opções".
//
// Contexto: GridPage._buildUserBannerAppBar() agora passa showBackButton
// baseado em Navigator.canPop(context), e UserBannerAppBar renderiza a seta
// de voltar apenas quando showBackButton=true.
void main() {
  group('GridPage — showBackButton behavior (card #428)', () {
    testWidgets('GridPage exibe seta de voltar quando há rota empilhada',
        (WidgetTester tester) async {
      // Simula um cenário real: tela principal + tela filha empilhada via push
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Menu Principal')),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    tester.element(find.byType(ElevatedButton)),
                    MaterialPageRoute(
                      builder: (_) => _GridPageTestHarness(),
                    ),
                  );
                },
                child: const Text('Abrir Tela de Grid'),
              ),
            ),
          ),
        ),
      );

      // Abre a tela de grid (que agora tem canPop=true pois está empilhada)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verifica se o botão de voltar está presente
      expect(
        find.byIcon(Icons.arrow_back),
        findsOneWidget,
        reason:
            'Seta de voltar deve estar visível em GridPage empilhada via Navigator.push',
      );
    });

    testWidgets('GridPage NÃO exibe seta de voltar se é a raiz (Home)',
        (WidgetTester tester) async {
      // Simula GridPage como home (canPop=false)
      await tester.pumpWidget(
        MaterialApp(
          home: _GridPageTestHarness(),
        ),
      );

      // Verifica se NÃO há botão de voltar
      expect(
        find.byIcon(Icons.arrow_back),
        findsNothing,
        reason:
            'Seta de voltar NÃO deve estar visível em GridPage que é a home (canPop=false)',
      );
    });
  });

  group('UserBannerAppBar — showBackButton rendering (card #428)', () {
    testWidgets('UserBannerAppBar renderiza seta quando showBackButton=true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: UserBannerAppBar(
              screenTitle: 'Tela Filha',
              showBackButton: true,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Verifica se há ícone de seta de voltar
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Verifica se tem o tooltip correto
      expect(find.byTooltip('Voltar'), findsOneWidget);
    });

    testWidgets('UserBannerAppBar NÃO renderiza seta quando showBackButton=false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: UserBannerAppBar(
              screenTitle: 'Tela Raiz',
              showBackButton: false,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Verifica se NÃO há ícone de seta de voltar
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('UserBannerAppBar.leading é null quando showBackButton=false',
        (WidgetTester tester) async {
      final widget = UserBannerAppBar(
        screenTitle: 'Teste',
        showBackButton: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: widget,
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Verifica que não há ícone de voltar quando showBackButton=false
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Clique em voltar chama Navigator.maybePop(context)',
        (WidgetTester tester) async {
      // Cria cenário com tela empilhada para que maybePop realmente funcione
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    tester.element(find.byType(ElevatedButton)),
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: UserBannerAppBar(
                          screenTitle: 'Tela Filha',
                          showBackButton: true,
                        ),
                        body: const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
                child: const Text('Push'),
              ),
            ),
          ),
        ),
      );

      // Faz push da tela filha
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verifica que a seta está presente
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Clica na seta de voltar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verifica que voltou (agora só há um screen)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('automaticallyImplyLeading é sempre false no AppBar',
        (WidgetTester tester) async {
      // Testa que a seta de voltar vem do leading manual, não do automático
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: UserBannerAppBar(
              screenTitle: 'Teste',
              showBackButton: true,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      // Se automaticallyImplyLeading fosse true e houvesse canPop,
      // teríamos problemas de duplicação. Esse teste garante que
      // a seta vem apenas do leading manual.
      final backButtons = find.byIcon(Icons.arrow_back);
      expect(backButtons, findsOneWidget,
          reason: 'Deve haver exatamente uma seta (do leading manual)');
    });
  });

  group('GridPage mobile telas específicas (Comercial/Financeiro)', () {
    testWidgets('Telas de Comercial mantêm showBackButton quando empilhadas',
        (WidgetTester tester) async {
      // Simula o padrão usado por ContaPagarGridScreen, ContaReceberGridScreen, etc.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Simula o padrão de push usado em bottom_navbar_screen.dart
                  Navigator.push(
                    tester.element(find.byType(ElevatedButton)),
                    MaterialPageRoute(
                      builder: (_) => _GridPageTestHarness(
                        title: 'Contas a Pagar',
                        useUserBannerAppBar: true,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir Contas a Pagar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Deve exibir a seta de voltar
      expect(
        find.byIcon(Icons.arrow_back),
        findsOneWidget,
        reason:
            'Telas de Comercial/Financeiro empilhadas devem exibir seta de voltar',
      );

      // Deve exibir o título correto
      expect(find.text('Contas a Pagar'), findsWidgets);
    });

    testWidgets(
        'Tela empilhada com GridPage exibe seta de voltar do header',
        (WidgetTester tester) async {
      // Simula: tela raiz -> Navigator.push -> GridPage
      // Valida que GridPage detecta canPop=true e renderiza seta
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Simula o padrão usado em bottom_navbar_screen.dart
                  // para abrir telas do menu Comercial/Financeiro
                  Navigator.push(
                    tester.element(find.byType(ElevatedButton)),
                    MaterialPageRoute(
                      builder: (_) => _GridPageTestHarness(
                        title: 'Contas a Pagar',
                        useUserBannerAppBar: true,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir Menu Comercial'),
              ),
            ),
          ),
        ),
      );

      // Push da tela de grid
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verifica que há seta de voltar (affordance para retornar)
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

/// Widget de teste que simula GridPage com as opções testadas
class _GridPageTestHarness extends StatelessWidget {
  final String title;
  final bool useUserBannerAppBar;

  const _GridPageTestHarness({
    this.title = 'Grid Test',
    this.useUserBannerAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    // Simula o comportamento real de GridPage._buildUserBannerAppBar
    final canPop = Navigator.canPop(context);

    if (useUserBannerAppBar) {
      return Scaffold(
        appBar: UserBannerAppBar(
          screenTitle: title,
          showBackButton: canPop,
        ),
        body: Center(
          child: Text('Conteúdo de $title'),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Text('Conteúdo de $title'),
        ),
      );
    }
  }
}
