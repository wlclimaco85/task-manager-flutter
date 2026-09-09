import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/mobile/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

// Bug real reportado pelo usuario (video): ao tocar na aba GED sem ter
// permissao pra ela, a tela ficava completamente em branco -- sem erro,
// sem mensagem, parecendo travada/quebrada. Causa raiz:
// _buildGatedPlaceholder(msg) em bottom_navbar_screen.dart ignorava o
// parametro 'msg' e retornava SizedBox.shrink() (nada visivel). O mesmo bug
// afetava as outras 4 abas gateadas (Calendario/Chat/Comunicados/Chamados),
// nao so GED.
void main() {
  tearDown(() {
    AuthUtility.userInfo = null;
    ModuloAccess.reset();
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

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();

      // Abre a aba GED (indice 4 na barra: Inicio, Chat, Comunicados,
      // Chamados, GED, Mais).
      await tester.tap(find.text('GED'));
      await tester.pump();

      expect(find.text('GED indisponível'), findsOneWidget);
      expect(
        find.textContaining('solicitar acesso'),
        findsOneWidget,
      );

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
      await tester.pumpAndSettle();

      expect(find.text('GME'), findsNothing);
      expect(find.text('Service Desk'), findsNothing);
      expect(find.text('Projetos'), findsNothing);
      expect(find.text('Precificação'), findsNothing);

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
      await tester.pumpAndSettle();

      expect(find.text('GME'), findsOneWidget);
      // Os outros 3 continuam escondidos -- so' GME foi contratado.
      expect(find.text('Service Desk'), findsNothing);
      expect(find.text('Projetos'), findsNothing);
      expect(find.text('Precificação'), findsNothing);

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    },
  );
}
