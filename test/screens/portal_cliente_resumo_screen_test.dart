// test/screens/portal_cliente_resumo_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/portal_cliente_resumo_model.dart';
import 'package:task_manager_flutter/services/portal_cliente_caller.dart';
import 'package:task_manager_flutter/screens/contabil/portal_cliente_resumo_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PortalClienteResumo', () {
    // TEST 1 (RED): Desserialização de JSON
    test('fromJson() desserializa saldo, docsPendentes e alertas corretamente', () {
      final json = {
        'saldo': 15000.00,
        'docsPendentes': 3,
        'alertas': 5,
      };

      final resumo = PortalClienteResumo.fromJson(json);

      expect(resumo.saldo, 15000.00);
      expect(resumo.docsPendentes, 3);
      expect(resumo.alertas, 5);
    });

    // TEST 1B: Serialização de volta para JSON
    test('toJson() serializa para mapa correto', () {
      final resumo = PortalClienteResumo(
        saldo: 15000.00,
        docsPendentes: 3,
        alertas: 5,
      );

      final json = resumo.toJson();

      expect(json['saldo'], 15000.00);
      expect(json['docsPendentes'], 3);
      expect(json['alertas'], 5);
    });
  });

  group('PortalClienteResumoScreen', () {
    // TEST 2 (RED): Widget renderiza sem erro
    testWidgets('PortalClienteResumoScreen renderiza 3 KPI cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const PortalClienteResumoScreen(empresaId: 20000),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se renderiza 3 cards (saldo, docs pendentes, alertas)
      expect(find.byType(Card), findsWidgets);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });

    // TEST 3 (RED): Valores renderizados corretamente
    testWidgets('PortalClienteResumoScreen mostra valores formatados',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const PortalClienteResumoScreen(empresaId: 20000),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica se mostra labels dos cards
      expect(find.text('Saldo'), findsOneWidget);
      expect(find.text('Documentos Pendentes'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
    });
  });
}
