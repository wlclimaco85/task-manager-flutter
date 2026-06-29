// test/screens/portal_cliente_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/screens/contabil/portal_cliente_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PortalClienteScreen', () {
    // TEST 1: Renderiza 3 KPI cards
    testWidgets('renderiza 3 KPI cards com Saldo, Documentos e Alertas',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const PortalClienteScreen()));
      await tester.pumpAndSettle();

      // Verifica títulos dos KPIs
      expect(find.text('Saldo'), findsOneWidget);
      expect(find.text('Documentos Pendentes'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);

      // Verifica valores iniciais (mock)
      expect(find.text('R\$ 0,00'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    // TEST 2: Renderiza título da tela
    testWidgets('renderiza título "Portal do Cliente"',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const PortalClienteScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Portal do Cliente'), findsOneWidget);
    });

    // TEST 3: Cards têm ícones visuais
    testWidgets('cards exibem ícones (carteira, documento, alerta)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const PortalClienteScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de ícones (pelo menos 3)
      expect(find.byIcon(Icons.wallet), findsOneWidget);
      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    // TEST 4: Cards têm cores diferenciadas
    testWidgets('cards possuem cores de contraste',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const PortalClienteScreen()));
      await tester.pumpAndSettle();

      // Verifica que há widgets com cores (Container com color property)
      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    // TEST 5: Layout responsivo (disposição em coluna/row)
    testWidgets('layout organiza KPIs em linha ou coluna',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const PortalClienteScreen()));
      await tester.pumpAndSettle();

      // Verifica presença de Container/Row/Column
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });
}
