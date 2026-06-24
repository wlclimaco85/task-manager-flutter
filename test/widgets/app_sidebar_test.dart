import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/app_sidebar.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('AppSidebar', () {
    Widget buildSidebar({
      bool isCollapsed = false,
      int selectedIndex = 0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AppSidebar(
            selectedIndex: selectedIndex,
            isCollapsed: isCollapsed,
            onSelect: (MenuItem item) {},
            onToggleCollapse: () {},
            unreadAlerts: 0,
            onNotificationTap: () {},
            onLogout: () {},
            userName: 'Usuário Teste',
            userEmail: 'teste@exemplo.com',
          ),
        ),
      );
    }

    testWidgets('renderiza nome e email do usuario', (tester) async {
      await tester.pumpWidget(buildSidebar());

      expect(find.text('Usuário Teste'), findsOneWidget);
      expect(find.text('teste@exemplo.com'), findsOneWidget);
    });

    testWidgets('renderiza foto do avatar (CircleAvatar)', (tester) async {
      await tester.pumpWidget(buildSidebar());

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('renderiza icone de notificacao e logout', (tester) async {
      await tester.pumpWidget(buildSidebar());

      expect(find.byIcon(Icons.notifications), findsWidgets);
      expect(find.byIcon(Icons.logout), findsWidgets);
    });

    testWidgets('exibe menu de navegacao basico', (tester) async {
      await tester.pumpWidget(buildSidebar());

      // Sidebar deve ter uma ListView com itens de menu
      expect(find.byType(ListView), findsWidgets);
    });
  });
}
