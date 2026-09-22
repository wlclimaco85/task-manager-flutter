import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:task_manager_flutter/mobile/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

// Bug real reportado pelo usuario (video): ao tocar na aba GED sem ter
// permissao pra ela, a tela ficava completamente em branco -- sem erro,
// sem mensagem, parecendo travada/quebrada. Causa raiz:
// _buildGatedPlaceholder(msg) em bottom_navbar_screen.dart ignorava o
// parametro 'msg' e retornava SizedBox.shrink() (nada visivel). O mesmo bug
// afetava as outras 4 abas gateadas (Calendario/Chat/Comunicados/Chamados),
// nao so GED.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  RolePermissaoItem permView(String telaNome) => RolePermissaoItem(
        telaNome: telaNome,
        podeVer: true,
        podeInserir: false,
        podeEditar: false,
        podeDeletar: false,
      );

  tearDown(() {
    AuthUtility.userInfo = null;
    ModuloAccess.reset();
    PermissionService().clear();
  });

  testWidgets(
    'aba GED sem permissao mostra mensagem "GED indisponivel" em vez de tela em branco',
    (tester) async {
      // Ver comentario no fim do teste sobre por que isso e' capturado.
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      // Login sem nenhuma permissao configurada (permissoes: [], roles: [])
      // -- exatamente o cenario de "sem acesso" que deixava a aba em branco.
      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      PermissionService().setPermissoes(const []);
      ModuloAccess.setContratadosParaTeste(const ['Chat']);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      // Abre a aba GED (indice 4 na barra: Inicio, Chat, Comunicados,
      // Chamados, GED, Mais).
      await tester.tap(find.text('GED'));
      await tester.pump();

      expect(find.textContaining('GED indispon'), findsOneWidget);
      expect(
        find.textContaining('não possui permissão'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));

      // BottomNavBarScreen dispara AppLogger.i.initCapture() (via widget
      // descendente) que reatribui debugPrint e FlutterError.onError pra
      // capturar logs no "Console de Logs" -- efeito colateral
      // pre-existente do app, nao relacionado a este bug. O framework de
      // teste verifica essas variaveis globais antes de rodar o tearDown,
      // entao a restauracao tem que acontecer aqui dentro do proprio teste.
      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  // Bug real reportado pelo usuario (produção, 3 dias): com a MESMA conta e
  // a MESMA permissao liberada no admin (tela "Arquivos"), o GED aparecia
  // certinho no web e continuava "indisponivel" no mobile, mesmo apos
  // reinstalar o app e relogar. Causa raiz: mobile checava
  // SecurityMatrix.canView(AppScreen.ged) (chave 'ged'), enquanto o web
  // (app_sidebar.dart) checa PermissionService.canViewScreen('ged'), que
  // traduz pra tela_nome real 'Arquivos' via _menuIdToTelaNome -- a
  // permissao gravada no banco usa 'Arquivos', entao so' o caminho do web
  // encontrava. Este teste prova que o mobile agora usa o mesmo mecanismo.
  testWidgets(
    'aba GED aparece quando a permissao "Arquivos" (telaNome real do backend) esta liberada',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      // Igual a producao: permissao gravada com telaNome 'Arquivos' (nao
      // 'ged') -- e o que o cadastro em Sistema > Perfis realmente grava.
      PermissionService().setPermissoes(const [
        RolePermissaoItem(
          telaNome: 'Arquivos',
          podeVer: true,
          podeInserir: false,
          podeEditar: false,
          podeDeletar: true,
        ),
      ]);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('GED'));
      await tester.pump();

      expect(find.text('GED indisponível'), findsNothing);

      // A grid do GED tenta buscar config real da tela via rede (sem backend
      // no teste, falha e cai no AppLogger.warn -> SistemaErrorReporter, que
      // agenda um timer de 1.5s). Sem deixar esse timer disparar, o teste
      // termina com "Timer is still pending" -- nao e' bug deste teste, e'
      // o comportamento normal de retry/log de erro de rede.
      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  // Bug real reportado pelo usuario (video/screenshots): o menu "Mais
  // opções" mostrava os grupos GME, Service Desk, Projetos e Precificação
  // pra QUALQUER usuario, mesmo sem o modulo contratado e sem nenhuma
  // permissao de tela -- os itens desses 4 grupos ainda nao tem
  // AppScreen/RBAC modelado, entao nunca passavam pelo sec.canView() usado
  // pelos outros grupos (Comercial/Financeiro/etc.), ficando sempre
  // visiveis independente de contrato.
  testWidgets(
    'menu "Mais opções" esconde GME/Service Desk/Projetos/Precificação quando nao contratados',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      // Nenhum modulo contratado.
      ModuloAccess.setContratadosParaTeste(const []);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('Mais'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('GME'), findsNothing);
      expect(find.text('Service Desk'), findsNothing);
      expect(find.text('Projetos'), findsNothing);
      expect(find.text('Precificação'), findsNothing);

      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  testWidgets(
    'menu "Mais opções" mostra GME quando o modulo esta contratado',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      ModuloAccess.setContratadosParaTeste(const ['GME']);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('Mais'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('GME'), findsOneWidget);
      // Os outros 3 continuam escondidos -- so' GME foi contratado.
      expect(find.text('Service Desk'), findsNothing);
      expect(find.text('Projetos'), findsNothing);
      expect(find.text('Precificação'), findsNothing);

      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  testWidgets(
    'menu Mais esconde atalhos pagos quando ha permissao mas nao ha modulo contratado',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      PermissionService().setPermissoes([
        permView('PdvNfce'),
        permView('Produtos'),
        permView('Parceiros'),
        permView('DashboardComercial'),
        permView('ContasPagar'),
        permView('ContasReceber'),
        permView('ContaBancaria'),
        permView('Dashboard'),
        permView('DashboardFinanceiro'),
        permView('Nfse'),
        permView('NfseSerie'),
        permView('NfseServico'),
        permView('ConfigFiscal'),
        permView('DashboardFiscal'),
      ]);
      ModuloAccess.setContratadosParaTeste(const []);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('Mais'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('PDV'), findsNothing);
      expect(find.text('Produtos'), findsNothing);
      expect(find.text('NFS-e'), findsNothing);
      expect(find.text('Config ISS'), findsNothing);
      expect(find.text('Régua de Cobrança'), findsNothing);
      expect(find.text('Agendar NFe Recorrente'), findsNothing);
      expect(find.text('Config Fiscal'), findsNothing);

      expect(find.text('Parceiros'), findsWidgets);
      expect(find.text('Dashboard Comercial'), findsOneWidget);
      expect(find.text('Contas Pagar'), findsOneWidget);
      expect(find.text('Contas Receber'), findsOneWidget);
      expect(find.text('Contas Bancarias'), findsOneWidget);
      expect(find.text('Dashboard Fiscal'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  testWidgets(
    'menu Mais respeita permissoes da role para modulos contratados (mostra apenas permitidos)',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      // Contratou Comercial e Financeiro, mas na Role só tem Parceiros e ContasReceber
      ModuloAccess.setContratadosParaTeste(const ['Comercial', 'Financeiro']);
      PermissionService().setPermissoes([
        permView('Parceiros'),
        permView('ContasReceber'),
      ]);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('Mais'));
      await tester.pump(const Duration(milliseconds: 350));

      // Liberados pela Role
      expect(find.text('Parceiros'), findsWidgets);
      expect(find.text('Contas Receber'), findsOneWidget);

      // Negados pela Role mesmo com módulo contratado
      expect(find.text('Produtos'), findsNothing);
      expect(find.text('Dashboard Comercial'), findsNothing);
      expect(find.text('Contas Pagar'), findsNothing);
      expect(find.text('Contas Bancarias'), findsNothing);

      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );

  testWidgets(
    'menu Mais mostra atalhos pagos quando os modulos correspondentes estao contratados',
    (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      PermissionService().setPermissoes([
        permView('PdvNfce'),
        permView('Produtos'),
        permView('Parceiros'),
        permView('DashboardComercial'),
        permView('ContasReceber'),
        permView('Nfse'),
        permView('NfseSerie'),
        permView('NfseServico'),
        permView('ConfigFiscal'),
        permView('DashboardFiscal'),
      ]);
      ModuloAccess.setContratadosParaTeste(const [
        'Comercial',
        'Financeiro',
        'NFC-e',
        'NFS-e',
        'Financeiro avançado',
      ]);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      await tester.tap(find.text('Mais'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('PDV'), findsOneWidget);
      expect(find.text('Produtos'), findsOneWidget);
      expect(find.text('NFS-e'), findsOneWidget);
      expect(find.text('Config ISS'), findsOneWidget);
      expect(find.text('Régua de Cobrança'), findsOneWidget);
      expect(find.text('Agendar NFe Recorrente'), findsOneWidget);
      expect(find.text('Config Fiscal'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );
}
