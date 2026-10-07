import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/nfse_faturar_utils.dart';
import 'package:task_manager_flutter/widgets/nfse_faturar_dialog.dart';

void main() {
  testWidgets('popUp abre com mes anterior, ano e Faturar desabilitado sem tomador',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showNfseFaturarDialog(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Faturar NFS-e'), findsOneWidget);
    expect(find.byKey(const Key('nfse_faturar_mes')), findsOneWidget);
    final padrao = nfseCompetenciaPadrao(DateTime.now());
    expect(find.text(nfseNomeMes(padrao.mes)), findsWidgets);
    expect(find.text('${padrao.ano}'), findsWidgets);

    final botao = tester.widget<FilledButton>(
        find.byKey(const Key('nfse_faturar_confirmar')));
    expect(botao.onPressed, isNull);
  });
}
