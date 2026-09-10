import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  group('FilterActionBar', () {
    testWidgets('renderiza com botoes de refresh e filtro', (tester) async {
      await tester.pumpWidget(_wrap(FilterActionBar(
        onRefresh: () {},
        onFilterToggle: () {},
      )));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('isLoading desabilita botao refresh', (tester) async {
      await tester.pumpWidget(_wrap(FilterActionBar(
        onRefresh: () {},
        isLoading: true,
      )));
      final btn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Recarregar dados'),
          matching: find.byType(IconButton),
        ),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('onRefresh eh chamado ao clicar', (tester) async {
      bool chamado = false;
      await tester.pumpWidget(_wrap(FilterActionBar(
        onRefresh: () => chamado = true,
      )));
      await tester.tap(find.byIcon(Icons.refresh));
      expect(chamado, isTrue);
    });

    testWidgets('onFilterToggle eh chamado ao clicar', (tester) async {
      bool chamado = false;
      await tester.pumpWidget(_wrap(FilterActionBar(
        onFilterToggle: () => chamado = true,
      )));
      await tester.tap(find.byIcon(Icons.filter_list));
      expect(chamado, isTrue);
    });
  });

  group('SimpleAppBar', () {
    testWidgets('exibe titulo', (tester) async {
      await tester.pumpWidget(_wrap(SimpleAppBar(title: 'Teste')));
      expect(find.text('Teste'), findsOneWidget);
    });

    testWidgets('exibe icone padrao quando nao especificado', (tester) async {
      await tester.pumpWidget(_wrap(SimpleAppBar(title: 'Teste')));
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
    });

    testWidgets('exibe icone customizado', (tester) async {
      await tester.pumpWidget(_wrap(SimpleAppBar(
        title: 'Teste',
        icon: Icons.star,
      )));
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('AppBarActions', () {
    testWidgets('exibe icone de notificacao e logout', (tester) async {
      AuthUtility.userInfo = LoginModel(token: 'fake');
      addTearDown(() => AuthUtility.userInfo = null);
      await tester.pumpWidget(_wrap(const AppBarActions()));
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });
  });
}
