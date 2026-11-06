import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_faturar_utils.dart';
import 'package:task_manager_flutter/utils/parceiro_faturamento_utils.dart';
import 'package:task_manager_flutter/widgets/parceiro_faturamento_dialog.dart';

void main() {
  test('payload leva a referencia (mes/ano) escolhida no popUp', () {
    final payload = ParceiroFaturamentoUtils.buildPayload(
      parceiroIds: [10],
      todos: false,
      produtoId: 30,
      serieId: 40,
      observacao: ' Servico - Setembro/2026 ',
      mesReferencia: 9,
      anoReferencia: 2026,
    );
    expect(payload['mesReferencia'], 9);
    expect(payload['anoReferencia'], 2026);
    expect(payload['observacao'], 'Servico - Setembro/2026');
  });

  test('payload sem referencia nao envia mes/ano (backend assume mes anterior)', () {
    final payload = ParceiroFaturamentoUtils.buildPayload(
      parceiroIds: [10],
      todos: false,
      produtoId: 30,
      serieId: 40,
      observacao: 'x',
    );
    expect(payload.containsKey('mesReferencia'), isFalse);
    expect(payload.containsKey('anoReferencia'), isFalse);
  });

  test('observacao padrao descreve o mes ANTERIOR a referencia, inclusive virada de ano', () {
    expect(ParceiroFaturamentoUtils.observacaoPadraoCompetencia('Servico', 9, 2026),
        'Servico - Agosto/2026');
    expect(ParceiroFaturamentoUtils.observacaoPadraoCompetencia('Servico', 11, 2026),
        'Servico - Outubro/2026');
    expect(ParceiroFaturamentoUtils.observacaoPadraoCompetencia('Servico', 1, 2026),
        'Servico - Dezembro/2025');
  });

  testWidgets('popUp Faturar abre com o mes e ano atuais como referencia', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ParceiroFaturamentoDialog(parceiroIds: [10], todos: false),
      ),
    ));
    await tester.pump();

    final hoje = DateTime.now();
    expect(find.byKey(const Key('parceiro_faturar_mes')), findsOneWidget);
    expect(find.byKey(const Key('parceiro_faturar_ano')), findsOneWidget);
    expect(find.text(nfseNomeMes(hoje.month)), findsWidgets);
    expect(find.text('${hoje.year}'), findsWidgets);
  });
}
