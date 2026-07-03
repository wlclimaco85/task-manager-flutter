import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/widgets/app_sidebar.dart';

void main() {
  group('AppSidebar', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthUtility.userInfo = null;
    });

    tearDown(() {
      AuthUtility.userInfo = null;
    });

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
            userName: 'Usuario Teste',
            userEmail: 'teste@exemplo.com',
          ),
        ),
      );
    }

    void allowMenuIds(List<String> ids) {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(
          id: 1,
          tipoLogin: LoginEnum.APP_ABRACO,
        ),
        permissoes: ids
            .map((id) => RolePermissaoItem(
                  telaNome: id,
                  podeVer: true,
                  podeInserir: false,
                  podeEditar: false,
                  podeDeletar: false,
                ))
            .toList(),
      );
    }

    testWidgets('renderiza email como identificador principal do usuario',
        (tester) async {
      await tester.pumpWidget(buildSidebar());

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

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('recalcula grupo expandido quando a tela selecionada muda',
        (tester) async {
      await tester.pumpWidget(buildSidebar(selectedIndex: 25));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Financeiro'), findsOneWidget);
      expect(find.text('Contas a Pagar'), findsOneWidget);
      expect(find.text('PDV / NFC-e'), findsNothing);

      await tester.pumpWidget(buildSidebar(selectedIndex: 80));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Fiscal / NFC-e'), findsOneWidget);
      expect(find.text('PDV / NFC-e'), findsOneWidget);
      expect(find.text('Contas a Pagar'), findsNothing);
    });

    testWidgets('renderiza itens flat quando so um grupo fica visivel',
        (tester) async {
      allowMenuIds(['contas_pagar']);

      await tester.pumpWidget(buildSidebar(selectedIndex: 25));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Contas a Pagar'), findsOneWidget);
      expect(find.text('Financeiro'), findsNothing);
      expect(find.text('Fiscal / NFC-e'), findsNothing);
    });

    testWidgets('abre dois grupos por padrao quando ambos ficam visiveis',
        (tester) async {
      allowMenuIds(['contas_pagar', 'pdv_nfce']);

      await tester.pumpWidget(buildSidebar(selectedIndex: 25));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Financeiro'), findsOneWidget);
      expect(find.text('Contas a Pagar'), findsOneWidget);
      expect(find.text('Fiscal / NFC-e'), findsOneWidget);
      expect(find.text('PDV / NFC-e'), findsOneWidget);
    });
  });
}
