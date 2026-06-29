import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/permissao_helper.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';
import 'package:task_manager_flutter/widgets/action_gate.dart';

void main() {
  group('ActionGate Widget Tests', () {
    // Constrói um LoginModel com permissões específicas para testes
    LoginModel _buildUserWithPermissions({
      required Map<AppScreen, Set<AppAction>> permissions,
    }) {
      final permissoes = <RolePermissaoItem>[];

      // Mapeia cada screen → ações permitidas → RolePermissaoItem
      permissions.forEach((screen, actions) {
        permissoes.add(
          RolePermissaoItem(
            telaNome: screen.name,
            podeVer: actions.contains(AppAction.view),
            podeInserir: actions.contains(AppAction.insert),
            podeEditar: actions.contains(AppAction.update),
            podeDeletar: actions.contains(AppAction.delete),
            podeBaixar: actions.contains(AppAction.baixar),
          ),
        );
      });

      return LoginModel(
        token: 'test-token',
        login: Login(
          id: 1,
          tipoLogin: LoginEnum.APP_ABRACO,
          roles: [Role(id: 1, key: 'ROLE_TEST', description: 'Test Role')],
          parceiro: Parceiro(id: 1, nome: 'Test Company'),
        ),
        permissoes: permissoes,
      );
    }

    setUp(() {
      ModuloAccess.reset();
      ModuloAccess.setContratadosParaTeste(['Financeiro']);
      AuthUtility.userInfo = null;
    });

    tearDown(() {
      AuthUtility.userInfo = null;
    });

    testWidgets('ActionGate renderiza child quando tem permissão (VIEW)',
        (WidgetTester tester) async {
      // Arrange: usuário com permissão de VIEW em CONTAS_PAGAR
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.view}
        },
      );
      AuthUtility.userInfo = userInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.view,
              child: const Text('Conteúdo Permitido'),
            ),
          ),
        ),
      );

      // Assert: widget deve renderizar
      expect(find.text('Conteúdo Permitido'), findsOneWidget);
    });

    testWidgets('ActionGate oculta child quando não tem permissão (INSERT)',
        (WidgetTester tester) async {
      // Arrange: usuário com apenas VIEW (não INSERT)
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.view} // Sem INSERT
        },
      );
      AuthUtility.userInfo = userInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.insert,
              child: const Text('Conteúdo Bloqueado'),
            ),
          ),
        ),
      );

      // Assert: widget não deve renderizar (SizedBox.shrink)
      expect(find.text('Conteúdo Bloqueado'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('ActionGate desabilita child quando disabledByState=true',
        (WidgetTester tester) async {
      // Arrange: usuário com permissão, mas estado do registro bloqueia ação
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.delete}
        },
      );
      AuthUtility.userInfo = userInfo;

      const testTooltip = 'Não pode deletar conta já baixada';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.delete,
              disabledByState: true,
              disabledTooltip: testTooltip,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Deletar'),
              ),
            ),
          ),
        ),
      );

      // Assert: botão deve estar envolvido em IgnorePointer + Opacity (desabilitado)
      // Verifica que há Tooltip (indicando desabilitação por estado)
      expect(find.byType(Tooltip), findsOneWidget);
      // Verifica que o texto do botão ainda está presente (mas desabilitado)
      expect(find.text('Deletar'), findsOneWidget);
    });

    testWidgets('ActionGate mostra tooltip quando disabledByState=true',
        (WidgetTester tester) async {
      // Arrange
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.update}
        },
      );
      AuthUtility.userInfo = userInfo;

      const testTooltip = 'Ação bloqueada por estado';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.update,
              disabledByState: true,
              disabledTooltip: testTooltip,
              child: const Text('Editar'),
            ),
          ),
        ),
      );

      // Assert: Tooltip deve estar presente
      expect(find.byType(Tooltip), findsOneWidget);

      final tooltip = find.byType(Tooltip).evaluate().first.widget as Tooltip;
      expect(tooltip.message, testTooltip);
    });

    testWidgets(
        'ActionGate usa tooltip padrão quando disabledByState=true e sem disabledTooltip',
        (WidgetTester tester) async {
      // Arrange
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.update}
        },
      );
      AuthUtility.userInfo = userInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.update,
              disabledByState: true,
              // disabledTooltip omitido — deve usar padrão
              child: const Text('Editar'),
            ),
          ),
        ),
      );

      // Assert: Tooltip com mensagem padrão
      final tooltip = find.byType(Tooltip).evaluate().first.widget as Tooltip;
      expect(tooltip.message, 'Ação não disponível neste estado');
    });

    testWidgets('ActionGate renderiza child normalmente quando disabledByState=false',
        (WidgetTester tester) async {
      // Arrange: permissão OK, estado OK
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.view}
        },
      );
      AuthUtility.userInfo = userInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionGate(
              screen: AppScreen.contasPagar,
              action: AppAction.view,
              disabledByState: false,
              child: const Text('Contenho Habilitado'),
            ),
          ),
        ),
      );

      // Assert: child sem wrapper de desabilitar (apenas verifica que o texto está presente)
      expect(find.text('Contenho Habilitado'), findsOneWidget);
      // Tooltip NÃO deve estar presente quando disabledByState=false
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('ActionGate bloqueia múltiplas ações conforme permissões',
        (WidgetTester tester) async {
      // Arrange: usuário com VIEW+INSERT, mas sem UPDATE+DELETE
      final userInfo = _buildUserWithPermissions(
        permissions: {
          AppScreen.contasPagar: {AppAction.view, AppAction.insert}
        },
      );
      AuthUtility.userInfo = userInfo;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ActionGate(
                  screen: AppScreen.contasPagar,
                  action: AppAction.view,
                  child: const Text('Ver'),
                ),
                ActionGate(
                  screen: AppScreen.contasPagar,
                  action: AppAction.insert,
                  child: const Text('Inserir'),
                ),
                ActionGate(
                  screen: AppScreen.contasPagar,
                  action: AppAction.update,
                  child: const Text('Editar'),
                ),
                ActionGate(
                  screen: AppScreen.contasPagar,
                  action: AppAction.delete,
                  child: const Text('Deletar'),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Ver'), findsOneWidget);
      expect(find.text('Inserir'), findsOneWidget);
      expect(find.text('Editar'), findsNothing); // Bloqueado
      expect(find.text('Deletar'), findsNothing); // Bloqueado
    });
  });
}
