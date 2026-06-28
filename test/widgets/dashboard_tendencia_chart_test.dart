import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/mes_cobranca_model.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/widgets/dashboard_tendencia_chart.dart';

void main() {
  group('DashboardTendenciaChart', () {
    testWidgets('renderiza gráfico com dados válidos', (WidgetTester tester) async {
      // Arrange
      final dados = [
        MesCobranca(mes: '2026-01', quantidade: 10, valor: 1000.0),
        MesCobranca(mes: '2026-02', quantidade: 15, valor: 1500.0),
        MesCobranca(mes: '2026-03', quantidade: 12, valor: 1200.0),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardTendenciaChart(dados: dados),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardTendenciaChart), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Tendência de Cobrança (6 Meses)'), findsOneWidget);
    });

    testWidgets('renderiza mensagem vazia quando sem dados', (WidgetTester tester) async {
      // Arrange
      const dados = <MesCobranca>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardTendenciaChart(dados: dados),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardTendenciaChart), findsOneWidget);
      expect(find.text('Nenhum dado disponível'), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renderiza tabela de resumo com dados', (WidgetTester tester) async {
      // Arrange
      final dados = [
        MesCobranca(mes: '2026-01', quantidade: 10, valor: 1000.0),
        MesCobranca(mes: '2026-02', quantidade: 15, valor: 1500.0),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardTendenciaChart(dados: dados),
          ),
        ),
      );

      // Assert
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Mês'), findsWidgets);
      expect(find.text('Qtd.'), findsWidgets);
      expect(find.text('Valor'), findsWidgets);
    });

    testWidgets('formata corretamente mes de "2026-01" para "Jan/26"', (WidgetTester tester) async {
      // Arrange
      final dados = [
        MesCobranca(mes: '2026-01', quantidade: 10, valor: 1000.0),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardTendenciaChart(dados: dados),
          ),
        ),
      );

      // Assert
      expect(find.text('Jan/26'), findsWidgets);
    });
  });
}
