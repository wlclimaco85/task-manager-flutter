import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/details/nfse_detail_screen.dart';

void main() {
  group('MobileNfseDetailScreen', () {
    testWidgets('renderiza a tela real de detalhe com acoes fiscais',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        home: MobileNfseDetailScreen(
          item: const {'id': 701, 'status': 'PENDENTE', 'numero': '10'},
        ),
      ));
      await tester.pump();

      expect(find.text('Dados da nota'), findsOneWidget);
      expect(find.text('Cliente / Tomador'), findsOneWidget);
      expect(find.text('Serviços da nota'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Emitir'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancelar'), findsOneWidget);
    });

    testWidgets('traduz status retornado pela prefeitura no mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(MaterialApp(
        home: MobileNfseDetailScreen(
          item: const {'id': 702, 'status': 'CANCELLED', 'numero': '11'},
        ),
      ));
      await tester.pump();

      expect(find.text('Cancelada na prefeitura'), findsOneWidget);
      expect(find.text('CANCELLED'), findsNothing);
      final cancelarBtn = tester.widget<OutlinedButton>(find.ancestor(
        of: find.text('Já cancelada'),
        matching: find.byType(OutlinedButton),
      ));
      expect(cancelarBtn.onPressed, isNull);
    });
  });
}
