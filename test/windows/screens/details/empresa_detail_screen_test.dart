// test/windows/screens/details/empresa_detail_screen_test.dart
//
// Mesmo teste de test/web/screens/details/empresa_detail_screen_test.dart,
// para a versao Windows (WindowsEmpresaDetailScreen).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/details/empresa_detail_screen.dart';

bool _alwaysAllow(String permission) => true;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  Widget buildScreen(Map<String, dynamic> item) {
    return MaterialApp(
      home:
          WindowsEmpresaDetailScreen(item: item, hasPermission: _alwaysAllow),
    );
  }

  group('WindowsEmpresaDetailScreen — gate de Modulo Servicos', () {
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
