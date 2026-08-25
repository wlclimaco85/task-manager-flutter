// test/windows/screens/details/parceiro_detail_screen_test.dart
//
// Mesmo teste de test/web/screens/details/parceiro_detail_screen_test.dart,
// para a versao Windows (WindowsParceiroDetailScreen).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/windows/screens/details/parceiro_detail_screen.dart';

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
          WindowsParceiroDetailScreen(item: item, hasPermission: _alwaysAllow),
    );
  }

  group('WindowsParceiroDetailScreen — gate de Modulo Servicos', () {
    testWidgets(
        'id null (parceiro novo): nao dispara fetch, libera o gate imediatamente e nao mostra erro',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'id presente + falha de rede: tela nao trava e mostra aviso de erro (sem excecao nao tratada)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen({'id': 42, 'nome': 'Parceiro X'}));
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
