import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/fiscal/nfe_authorization_status_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('NfeAuthorizationStatusBanner', () {
    testWidgets('mostra status pendente quando status vem vazio',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const NfeAuthorizationStatusBanner(status: '')),
      );

      expect(find.text('Status da autorização'), findsOneWidget);
      expect(find.text('PENDENTE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mantem progresso visivel e status longo com ellipsis',
        (tester) async {
      const status =
          'REJEITADA POR DUPLICIDADE DE NF-E COM CHAVE DE ACESSO INFORMADA PELA SEFAZ';

      await tester.pumpWidget(
        _wrap(const NfeAuthorizationStatusBanner(
          status: status,
          emitindo: true,
        )),
      );

      final statusText = tester.widget<Text>(find.text(status));

      expect(statusText.overflow, TextOverflow.ellipsis);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Transmitindo para a SEFAZ...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
