import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/nfe_cancelamento_extemporaneo_dialog.dart';

void main() {
  testWidgets('só transmite após confirmar a regra da SEFAZ e valida a justificativa', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: NfeCancelamentoExtemporaneoDialog(nfeId: '9'))));
    ElevatedButton botao() => t.widget(find.widgetWithText(ElevatedButton, 'Transmitir cancelamento'));
    expect(botao().onPressed, isNull);

    await t.ensureVisible(find.byKey(const Key('extemporaneo-liberado')));
    await t.tap(find.byKey(const Key('extemporaneo-liberado')));
    await t.pump();
    expect(botao().onPressed, isNotNull);

    await t.enterText(find.byKey(const Key('extemporaneo-motivo')), 'curto');
    await t.tap(find.text('Transmitir cancelamento'));
    await t.pump();
    expect(find.text('A justificativa deve ter de 15 a 255 caracteres.'), findsOneWidget);
  });

  test('rejeição 501 orienta pedir a liberação', () {
    final msg = erroCancelamentoExtemporaneo(
        500, '{"message":"SEFAZ rejeitou o cancelamento: prazo de cancelamento superior (cStat 501)"}');
    expect(msg, contains('cStat 501'));
    expect(msg, contains('Solicite a liberação'));
    expect(erroCancelamentoExtemporaneo(500, '{"message":"outra falha"}'), isNot(contains('liberação')));
  });
}
