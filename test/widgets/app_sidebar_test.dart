import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/string_utils.dart';
import 'package:task_manager_flutter/widgets/app_sidebar.dart';

const _avatarPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

void main() {
  group('AppSidebar', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AuthUtility.userInfo = null;
      PermissionService().clear();
    });

    tearDown(() {
      AuthUtility.userInfo = null;
      PermissionService().clear();
    });

    Widget buildSidebar({
      bool isCollapsed = false,
      int selectedIndex = 0,
      VoidCallback? onTrocarEmpresa,
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
            onTrocarEmpresa: onTrocarEmpresa,
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
        permissoes: ids.map((id) {
          // Converter snake_case para camelCase para corresponder aos AppScreen names
          final camelCase = StringUtils.snakeToCamelCase(id);
          return RolePermissaoItem(
            telaNome: camelCase,
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          );
        }).toList(),
      );
    }

    testWidgets('renderiza email como identificador principal do usuario',
        (tester) async {
      await tester.pumpWidget(buildSidebar());

      expect(find.text('teste@exemplo.com'), findsOneWidget);
    });

    testWidgets('renderiza email atualizado da sessao do usuario',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(email: 'brasilmodasurfltda@gmail.com'),
      );

      await tester.pumpWidget(buildSidebar());

      expect(find.text('brasilmodasurfltda@gmail.com'), findsOneWidget);
      expect(find.text('teste@exemplo.com'), findsNothing);
    });

    testWidgets('renderiza foto do avatar (CircleAvatar)', (tester) async {
      await tester.pumpWidget(buildSidebar());

      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('renderiza foto do login quando backend envia campo foto',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        data: Data.fromJson({
          'id': 1,
          'email': 'teste@exemplo.com',
          'photo': '',
          'foto': 'data:image/png;base64,$_avatarPngBase64',
        }),
      );

      await tester.pumpWidget(buildSidebar());

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        ),
        findsWidgets,
      );
    });

    testWidgets('atualiza avatar quando sessao do login recebe foto',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(
          id: 967,
          email: 'brasilmodasurfltda@gmail.com',
          nome: 'BRASIL MODA SURF LTDA',
        ),
      );

      await tester.pumpWidget(buildSidebar());
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        ),
        findsNothing,
      );

      await AuthUtility.setUserInfo(LoginModel(
        token: 'token-fake',
        login: Login(
          id: 967,
          email: 'brasilmodasurfltda@gmail.com',
          nome: 'BRASIL MODA SURF LTDA',
          foto: 'data:image/png;base64,$_avatarPngBase64',
        ),
      ));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is MemoryImage,
        ),
        findsWidgets,
      );
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
      allowMenuIds(['contas_pagar', 'pdv_nfce', 'chat']);

      await tester.pumpWidget(buildSidebar(selectedIndex: 25));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Financeiro'), findsOneWidget);
      expect(find.text('Contas a Pagar'), findsOneWidget);
      expect(find.text('PDV / NFC-e'), findsNothing);
      expect(find.text('Chat'), findsNothing);

      await tester.pumpWidget(buildSidebar(selectedIndex: 80));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Fiscal / NFC-e'), findsOneWidget);
      expect(find.text('PDV / NFC-e'), findsOneWidget);
      expect(find.text('Contas a Pagar'), findsNothing);
    });

    testWidgets('nao usa fallback antigo quando RBAC nega uma tela',
        (tester) async {
      allowMenuIds(['calendario', 'conta_bancaria']);

      await tester.pumpWidget(buildSidebar(selectedIndex: 80));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Fiscal / NFC-e'), findsNothing);
      expect(find.text('PDV / NFC-e'), findsNothing);
      expect(find.text('Config. Fiscal'), findsNothing);
      expect(find.text('Calendário'), findsOneWidget);
      expect(find.text('Conta Bancária'), findsOneWidget);
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

    testWidgets('exibe Trocar Empresa para login sem parceiro',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, email: 'contador@teste.com'),
      );
      var acionou = false;

      await tester.pumpWidget(buildSidebar(
        onTrocarEmpresa: () => acionou = true,
      ));

      expect(find.text('Trocar Empresa'), findsOneWidget);
      await tester.tap(find.text('Trocar Empresa'));
      expect(acionou, isTrue);
    });

    testWidgets('nao exibe Trocar Empresa para login com parceiro',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(
          id: 1,
          email: 'cliente@teste.com',
          parceiro: Parceiro(id: 99),
        ),
      );

      await tester.pumpWidget(buildSidebar(
        onTrocarEmpresa: () {},
      ));

      expect(find.text('Trocar Empresa'), findsNothing);
    });
  });
}
