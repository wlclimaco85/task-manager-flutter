import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager_flutter/features/escrituracao_fiscal/screens/escrituracao_list_screen.dart';
import 'package:task_manager_flutter/widgets/diagnostico_esocial/diagnostico_esocial_screen.dart';
import 'package:task_manager_flutter/widgets/gestao_xml/gestao_xml_screen.dart';
import 'package:task_manager_flutter/widgets/painel_fiscal/painel_fiscal_screen.dart';
import 'package:task_manager_flutter/widgets/user_banners.dart';

Future<http.Response> _semAcesso(String _) async => http.Response('', 403);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR', null);
  });

  final telas = <String, Widget Function(bool)>{
    'Painel Fiscal': (m) => PainelFiscalScreen(cabecalhoMobile: m, buscar: _semAcesso),
    'Diagnóstico eSocial': (m) => DiagnosticoEsocialScreen(cabecalhoMobile: m, buscar: _semAcesso),
    'Gestão de XML': (m) => GestaoXmlScreen(cabecalhoMobile: m, buscar: _semAcesso),
    'Escrituração Fiscal': (m) => EscrituracaoListScreen(cabecalhoMobile: m),
  };

  for (final tela in telas.entries) {
    for (final mobile in const [true, false]) {
      testWidgets('${tela.key}: cabeçalho do app só no celular ($mobile)', (t) async {
        t.view.physicalSize = Size(mobile ? 360 : 1366, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(home: tela.value(mobile)));
        await t.pumpAndSettle();

        expect(find.byType(UserBannerAppBar), mobile ? findsOneWidget : findsNothing);
        expect(find.byTooltip('Atualizar').evaluate().length + find.byIcon(Icons.refresh).evaluate().length,
            greaterThan(0));
        expect(t.takeException(), isNull);
      });
    }
  }
}
