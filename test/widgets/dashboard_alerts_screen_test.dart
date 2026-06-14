// test/widgets/dashboard_alerts_screen_test.dart
//
// Testes de widget para AlertListCard (cards de "Atrasados" e
// "Vencendo em X dias" do painel de alertas financeiros).
// Valida estado vazio, renderização de itens e cor aplicada ao ícone/trailing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/dashboard_alerts_screen.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

AlertItem _item({
  String tipo = 'PAGAR',
  int id = 1,
  String descricao = 'Conta de luz',
  double valor = 150.0,
  DateTime? dataVencimento,
}) =>
    AlertItem(tipo, id, descricao, valor, dataVencimento ?? DateTime(2026, 6, 10));

void main() {
  group('AlertListCard — estado vazio', () {
    testWidgets('lista vazia mostra mensagem "Nenhum lançamento."',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AlertListCard(
          title: 'Atrasados',
          items: [],
          color: GridColors.error,
        ),
      ));

      expect(find.text('Nenhum lançamento.'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('AlertListCard — lista com itens', () {
    testWidgets('exibe ListTile com descrição e valor', (tester) async {
      final itens = [
        _item(descricao: 'Aluguel', valor: 1200.5),
        _item(descricao: 'Energia', valor: 350.0),
      ];

      await tester.pumpWidget(_wrap(
        AlertListCard(
          title: 'Atrasados',
          items: itens,
          color: GridColors.error,
        ),
      ));

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Aluguel'), findsOneWidget);
      expect(find.text('Energia'), findsOneWidget);
      expect(find.textContaining('R\$ 1200.50'), findsOneWidget);
      expect(find.textContaining('R\$ 350.00'), findsOneWidget);
      expect(find.text('Nenhum lançamento.'), findsNothing);
    });

    testWidgets('aplica a cor recebida ao ícone e ao trailing',
        (tester) async {
      final itens = [_item(tipo: 'RECEBER')];

      await tester.pumpWidget(_wrap(
        AlertListCard(
          title: 'Vencendo em 5 dias',
          items: itens,
          color: GridColors.warning,
        ),
      ));

      final icone = tester.widget<Icon>(find.byIcon(Icons.warning));
      expect(icone.color, GridColors.warning);

      final trailing = tester.widget<Text>(find.text('RECEBER'));
      expect(trailing.style?.color, GridColors.warning);
    });
  });
}
