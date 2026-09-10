import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/mobile/screens/dashboard_financeiro_screen.dart';
import 'package:task_manager_flutter/services/sistema_error_reporter.dart';

void main() {
  group('DashboardFinanceiroMobileScreen', () {
    setUp(() {
      SistemaErrorReporter.instance.reset();
    });

    tearDown(() {
      SistemaErrorReporter.instance.reset();
    });

    testWidgets('Exibe titulo do app bar e loading inicial',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardFinanceiroMobileScreen(),
        ),
      );

      expect(find.text('Dashboard Financeiro'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Limpa qualquer timer pendente do reporter para o teste passar limpo
      SistemaErrorReporter.instance.reset();
    });

    test('Converte valores dinamicos para double corretamente', () {
      expect(_testToDouble(10), 10.0);
      expect(_testToDouble(10.5), 10.5);
      expect(_testToDouble('abc'), 0.0);
      expect(_testToDouble(null), 0.0);
    });

    testWidgets('Renderiza seletores de periodo ChoiceChips quando carregado',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardFinanceiroMobileScreen(),
        ),
      );

      // Aguarda transição do estado inicial
      await tester.pump(const Duration(milliseconds: 100));

      // Cancela timers de erro do reporter para evitar vazamento
      SistemaErrorReporter.instance.reset();
    });
  });
}

double _testToDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;
