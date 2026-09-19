import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:task_manager_flutter/mobile/screens/bottom_navbar_screen.dart';
import 'package:task_manager_flutter/mobile/screens/plano_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/tipo_parceiro_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/orcamento_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/pedido_venda_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/nfe_import_xml_screen.dart';
import 'package:task_manager_flutter/mobile/screens/nfse_import_xml_screen.dart';
import 'package:task_manager_flutter/mobile/screens/dre_screen.dart';
import 'package:task_manager_flutter/mobile/screens/cnab_remessa_screen.dart';
import 'package:task_manager_flutter/mobile/screens/forma_pagamento_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/feriado_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/setor_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/conta_contabil_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/alimento_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/academia_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/empresa_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/role_grid_screen.dart';
import 'package:task_manager_flutter/mobile/screens/trading_screens.dart';
import 'package:task_manager_flutter/customization/dynamic_grid_dynamic_screen.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  tearDown(() {
    AuthUtility.userInfo = null;
    ModuloAccess.reset();
    PermissionService().clear();
  });

  group('Mobile Screen Parity Tests', () {
    testWidgets('Dynamic grid screens instantiate with DynamicGridDynamicScreen', (tester) async {
      const screens = <Widget>[
        MobilePlanoGridScreen(),
        MobileTipoParceiroGridScreen(),
        MobileOrcamentoGridScreen(),
        MobilePedidoVendaGridScreen(),
        MobileFormaPagamentoGridScreen(),
        MobileFeriadoGridScreen(),
        MobileSetorGridScreen(),
        MobileContaContabilGridScreen(),
        MobileAlimentoGridScreen(),
        MobileAcademiaGridScreen(),
        MobileEmpresaGridScreen(),
        MobileRoleGridScreen(),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(MaterialApp(home: screen));
        expect(find.byType(DynamicGridDynamicScreen), findsOneWidget);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Functional wrapper screens instantiate with Scaffold and AppBar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileDreScreen()));
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.textContaining('DRE Gerencial'), findsWidgets);

      await tester.pumpWidget(const MaterialApp(home: MobileCnabRemessaScreen()));
      expect(find.textContaining('Envio EDI / Remessa CNAB'), findsWidgets);

      await tester.pumpWidget(const MaterialApp(home: MobileNfeImportXmlScreen()));
      expect(find.textContaining('Importar XML NF-e'), findsWidgets);

      await tester.pumpWidget(const MaterialApp(home: MobileNfseImportXmlScreen()));
      expect(find.textContaining('Importar XML NFS-e'), findsWidgets);

      await tester.pumpWidget(const MaterialApp(home: MobileTradingSinaisScreen()));
      expect(find.textContaining('Sinais de Mercado'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('BottomNavBarScreen compiles and renders for mobile', (tester) async {
      final originalDebugPrint = debugPrint;
      final originalOnError = FlutterError.onError;

      AuthUtility.userInfo = LoginModel(
        token: 'token-fake',
        login: Login(id: 1, tipoLogin: LoginEnum.APP_ABRACO, roles: const []),
        permissoes: const [],
      );
      PermissionService().setPermissoes(const []);
      ModuloAccess.setContratadosParaTeste(const ['Chat', 'Comercial', 'Financeiro', 'NFS-e', 'NFC-e']);

      await tester.pumpWidget(const MaterialApp(home: BottomNavBarScreen()));
      await tester.pump();
      expect(find.byType(BottomNavBarScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));

      debugPrint = originalDebugPrint;
      FlutterError.onError = originalOnError;
    });
  });
}
