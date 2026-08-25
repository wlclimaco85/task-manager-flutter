// test/web/screens/details/empresa_detail_screen_test.dart
//
// Testes de widget para o gate de carregamento de Modulo Servicos em
// WebEmpresaDetailScreen (mesmo padrao WR-03 aplicado nas telas de
// Parceiro). O campo 'modulosServico' e isInForm:false (nao vira multiselect
// no form principal -- modulos da Empresa sao editados via aba "Modulos de
// Cobranca"/EmpresaModulosTab), entao o unico comportamento observavel aqui
// e o gate de loading + tratamento de erro nao travar a tela.
//
// Nao ha backend disponivel no ambiente de teste: tanto o fetch de
// /api/empresa-modulo (nosso gate) quanto o FutureBuilder interno de
// GenericDetailFormScreen (que busca a TelaConfig) falham rapido, mas cada
// resolucao de Future so avanca a cada tester.pump() -- por isso usamos
// varias iteracoes de pump em vez de um unico pump longo.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/empresa_detail_screen.dart';

bool _alwaysAllow(String permission) => true;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  Widget buildScreen(Map<String, dynamic> item) {
    return MaterialApp(
      home: WebEmpresaDetailScreen(item: item, hasPermission: _alwaysAllow),
    );
  }

  group('WebEmpresaDetailScreen — gate de Modulo Servicos', () {
    testWidgets(
        'id null (empresa nova): nao dispara fetch, libera o gate imediatamente e nao mostra erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'id presente + falha de rede: tela nao trava e mostra aviso de erro (sem excecao nao tratada)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({'id': 7, 'nome': 'Empresa X'}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Modulo Servicos'),
        findsWidgets,
        reason:
            'aviso de falha ao carregar Modulo Servicos deve aparecer (SnackBar)',
      );
    });
  });
}
