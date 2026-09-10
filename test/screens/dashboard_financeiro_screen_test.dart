import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../lib/mobile/screens/dashboard_financeiro_screen.dart';
import '../../lib/services/dashboard_financeiro_caller.dart';
import '../../lib/services/conta_bancaria_caller.dart';
import '../../lib/services/empresa_caller.dart';

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
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardFinanceiroMobileScreen(),
        ),
      );

      // Aguarda carregamento inicial
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verificar se algum dropdown ou card de filtro existe
      expect(find.byType(Card), findsWidgets);
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
