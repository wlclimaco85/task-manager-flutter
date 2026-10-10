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

      // Mobile reutiliza a tela de detalhe web: secoes e acoes atuais.
      expect(find.text('Cabeçalho'), findsOneWidget);
      expect(find.text('Tomador'), findsOneWidget);
      expect(find.text('Itens (Serviços)'), findsOneWidget);
      expect(find.text('Totais'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
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
