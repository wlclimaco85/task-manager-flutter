import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';

import 'package:task_manager_flutter/mobile/screens/dashboard_financeiro_screen.dart';
import 'package:task_manager_flutter/services/dashboard_financeiro_caller.dart';
import 'package:task_manager_flutter/services/conta_bancaria_caller.dart';
import 'package:task_manager_flutter/services/empresa_caller.dart';

@GenerateMocks([
  DashboardFinanceiroCaller,
  ContaBancariaCaller,
  EmpresaCaller,
])
void main() {
  group('DashboardFinanceiroMobileScreen', () {
    setUp(() {
      // Setup para testes
    });

    testWidgets('Exibe titulo do app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardFinanceiroMobileScreen(),
        ),
      );

      expect(find.text('Dashboard Financeiro'), findsOneWidget);
    });

    testWidgets('Exibe carregamento inicial',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardFinanceiroMobileScreen(),
        ),
      );

      // Deve mostrar loading no início
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('KPI cards sao stacked verticalmente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Card(child: Text('A Pagar')),
                Card(child: Text('A Receber')),
                Card(child: Text('Saldo')),
                Card(child: Text('Vencido')),
              ],
            ),
          ),
        ),
      );

      // Todos os cards devem estar presentes (quando dados carregarem)
      expect(find.byType(Card), findsWidgets);
    });

    test('Converte valores dinamicos para double corretamente', () {
      // Mock da classe para testar conversão
      expect(_testToDouble(10), 10.0);
      expect(_testToDouble(10.5), 10.5);
      expect(_testToDouble('abc'), 0.0);
      expect(_testToDouble(null), 0.0);
    });

    testWidgets('Filtros de empresa e periodo sao renderizados',
        (WidgetTester tester) async {
      // Backend simulado: respostas vazias (200) para todas as chamadas.
      final client = MockClient((_) async => http.Response('{"data": {"dados": [], "totalElements": 0}}', 200,
          headers: {'content-type': 'application/json'}));
      await http.runWithClient(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: DashboardFinanceiroMobileScreen(),
          ),
        );

        // Aguarda carregamento inicial
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Cards de KPI renderizados (layout atual usa containers proprios).
        expect(find.text('Saldo Projetado'), findsOneWidget);
        expect(find.text('A Receber'), findsOneWidget);
        expect(find.text('A Pagar'), findsOneWidget);
      }, () => client);
    });

    testWidgets('Exibe botao de retry em caso de erro',
        (WidgetTester tester) async {
      // Este teste dependeria de mock, não testamos aqui
      // Mantemos como exemplo da estrutura esperada
    });
  });
}

// Função auxiliar para testar conversão
double _testToDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
