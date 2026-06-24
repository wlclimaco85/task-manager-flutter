import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/app_sidebar.dart';

Widget _wrapSidebar({
  bool isCollapsed = false,
  String userName = 'Usuario',
  String userEmail = 'user@test.com',
}) {
  return MaterialApp(
    home: Scaffold(
      body: AppSidebar(
        selectedIndex: 0,
        onSelect: (_) {},
        isCollapsed: isCollapsed,
        onToggleCollapse: () {},
        unreadAlerts: 0,
        onNotificationTap: () {},
        onLogout: () {},
        userName: userName,
        userEmail: userEmail,
      ),
    ),
  );
}

void main() {
  group('AppSidebar', () {
    testWidgets('exibe nome e email do usuario quando expandido', (tester) async {
      await tester.pumpWidget(_wrapSidebar(
        userName: 'Joao Silva',
        userEmail: 'joao@test.com',
      ));
      expect(find.text('Joao Silva'), findsOneWidget);
      expect(find.text('joao@test.com'), findsOneWidget);
    });

    testWidgets('nao exibe email quando recolhido', (tester) async {
      await tester.pumpWidget(_wrapSidebar(
        isCollapsed: true,
        userName: 'Joao',
        userEmail: 'joao@test.com',
      ));
      expect(find.text('joao@test.com'), findsNothing);
    });

    testWidgets('botao recolher/expandir funciona', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSidebar(
            selectedIndex: 0,
            onSelect: (_) {},
            isCollapsed: false,
            onToggleCollapse: () => toggled = true,
            unreadAlerts: 0,
            onNotificationTap: () {},
            onLogout: () {},
            userName: 'User',
            userEmail: 'user@test.com',
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(toggled, isTrue);
    });

    testWidgets('icone de logout aparece', (tester) async {
      await tester.pumpWidget(_wrapSidebar());
      expect(find.byIcon(Icons.logout), findsWidgets);
    });
  });
}
