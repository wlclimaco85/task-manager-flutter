import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/empresa_model.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/string_utils.dart';
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
            .map((id) {
              // Converter snake_case para camelCase para corresponder aos AppScreen names
              final camelCase = StringUtils.snakeToCamelCase(id);
              return RolePermissaoItem(
                telaNome: camelCase,
                podeVer: true,
                podeInserir: false,
                podeEditar: false,
                podeDeletar: false,
              );
            })
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

    // Bug de producao (2026-09-11): subtitulo abaixo do email mostrava o
    // nome da empresa/tenant mesmo quando o login tinha parceiro vinculado
    // (regra ja documentada em bugs.md/CLAUDE.md, regrediu nesta ordem).
    testWidgets(
        'exibe nome do PARCEIRO no subtitulo quando o login tem parceiro vinculado',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(
          id: 1,
          tipoLogin: LoginEnum.APP_ABRACO,
          empresa: Empresa(id: 10, nome: 'Abraco Contabilidade'),
          parceiro: Parceiro(id: 99, nome: 'Cliente XYZ Ltda'),
        ),
      );

      await tester.pumpWidget(buildSidebar());

      expect(find.text('Cliente XYZ Ltda'), findsOneWidget);
      expect(find.text('Abraco Contabilidade'), findsNothing);
    });

    testWidgets(
        'exibe nome da EMPRESA no subtitulo quando o login nao tem parceiro (usuario interno/master)',
        (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(
          id: 1,
          tipoLogin: LoginEnum.APP_ABRACO,
          empresa: Empresa(id: 10, nome: 'Abraco Contabilidade'),
        ),
      );

      await tester.pumpWidget(buildSidebar());

      expect(find.text('Abraco Contabilidade'), findsOneWidget);
    });

    // Achado de code review (2026-09-11): item 'sessoes' (Sistema > Sessões,
    // usado pra matar sessao de usuario) nao tem telaNome mapeado em
    // PermissionService -- sem guard proprio, dependeria 100% do backend
    // (SessaoAdminController ja restringe a MASTER via @PreAuthorize) e do
    // fallback legado de catalogo dinamico. Guard explicito garante que o
    // item nunca aparece pra role nao-master no Flutter, mesmo que o
    // catalogo dinamico venha a liberar por engano.
    testWidgets(
        'item "Sessões" NAO aparece pra usuario nao-master mesmo com permissao concedida no catalogo',
        (tester) async {
      allowMenuIds(['sessoes']); // tipoLogin APP_ABRACO (nao-master)

      await tester.pumpWidget(buildSidebar());
      await tester.enterText(find.byType(TextField), 'Sessões');
      await tester.pumpAndSettle();

      // 0 resultados -- so' o texto digitado no campo de busca (echo do
      // TextField) aparece, nunca um item de menu "Sessões" de verdade.
      expect(find.text('Nenhuma tela encontrada'), findsOneWidget);
    });

    testWidgets('item "Sessões" aparece pra usuario MASTER', (tester) async {
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.MASTER),
      );

      await tester.pumpWidget(buildSidebar());
      await tester.enterText(find.byType(TextField), 'Sessões');
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma tela encontrada'), findsNothing);
      // findsWidgets (nao findsOneWidget): o proprio TextField ecoa o texto
      // digitado, alem do resultado de menu -- aqui so' interessa provar
      // que o resultado de menu aparece (>= 1), nao a contagem exata.
      expect(find.text('Sessões'), findsWidgets);
    });
  });
}
