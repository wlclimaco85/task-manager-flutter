import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/details/nfse_detail_screen.dart';

/// Confirma que a versão web de [NfseDetailScreen] (usada em
/// lib/web/screens/details/nfse_detail_screen.dart) recebeu o mesmo
/// tratamento do card 6F94hyxf aplicado à versão windows: 6 seções
/// sequenciais reais (sem abas), busca inline sem Dialog e sem o antigo
/// layout de painéis lado a lado com divisor redimensionável (regressão
/// original do card, que a versão web ainda tinha antes desta correção).
void main() {
  testWidgets('Web: usa 6 secoes sequenciais em coluna unica (sem divisor lateral)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
    await tester.pump();

    const titulos = [
      'Dados da nota',
      'Cliente / Tomador',
      'Dados fiscais do serviço',
      'Serviços da nota',
      'Impostos retidos',
      'Totais',
    ];
    for (final titulo in titulos) {
      expect(find.text(titulo), findsOneWidget, reason: 'seção "$titulo"');
    }

    // Não deve haver mais o handle de arrastar (drag) do antigo layout de
    // colunas redimensionáveis por GestureDetector (cabeçalho estreito à
    // esquerda + grid de itens à direita).
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.byIcon(Icons.drag_handle), findsNothing);

    final dadosNota = tester.getTopLeft(find.text('Dados da nota'));
    final servicos = tester.getTopLeft(find.text('Serviços da nota'));
    expect(servicos.dx, dadosNota.dx);
    expect(servicos.dy, greaterThan(dadosNota.dy));
  });

  testWidgets('Web: busca abre popover inline, sem Dialog modal',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: const NfseDetailScreen(item: {})));
    await tester.pump();

    final serieField = find.widgetWithText(InputDecorator, 'Série');
    expect(serieField, findsOneWidget);
    await tester.tap(serieField);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Dialog), findsNothing);
    expect(find.textContaining('Buscar'), findsOneWidget);
  });
}
