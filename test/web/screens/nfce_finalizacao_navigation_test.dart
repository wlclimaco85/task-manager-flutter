import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/nfce/nfce_resultado_model.dart';
import 'package:task_manager_flutter/services/nfce_provider.dart';
import 'package:task_manager_flutter/web/screens/nfce/nfce_contingencia_screen.dart';
import 'package:task_manager_flutter/web/screens/nfce/nfce_finalizacao_screen.dart';

class _ContingenciaProvider extends NfceProvider {
  @override
  Future<NfceResultadoModel?> emitirNfce() async {
    return const NfceResultadoModel(
      id: 24,
      chaveAcesso: '31260919364209000162650010000000241131271224',
      protocolo: '',
      statusSefaz: 'CONTINGENCIA',
      motivoRejeicao: 'SEFAZ indisponivel. Nota em contingencia.',
    );
  }
}

void main() {
  testWidgets('Nova venda volta do modo contingencia para o PDV anterior',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NfceFinalizacaoScreen(
                        provider: _ContingenciaProvider(),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir finalizacao'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir finalizacao'));
    await tester.pumpAndSettle();

    expect(find.byType(NfceContingenciaScreen), findsOneWidget);

    await tester.tap(find.text('Nova venda'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir finalizacao'), findsOneWidget);
    expect(find.byType(NfceContingenciaScreen), findsNothing);
  });
}
