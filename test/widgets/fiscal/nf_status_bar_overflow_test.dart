import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/fiscal/nf_status_bar.dart';

void main() {
  testWidgets('NfStatusBar trunca titulo longo em largura estreita',
      (tester) async {
    const titulo =
        'Nova NF-e Saida com titulo operacional muito longo para auditoria';

    await tester.binding.setSurfaceSize(const Size(360, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: NfStatusBar(
            titulo: titulo,
            ambiente: 'HOMOLOGACAO',
            onSalvarRascunho: () {},
          ),
        ),
      ),
    );

    final titleText = tester.widget<Text>(find.text(titulo));

    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(find.byTooltip('Salvar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
