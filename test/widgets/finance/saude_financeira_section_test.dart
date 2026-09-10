import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/saude_financeira_model.dart';
import 'package:task_manager_flutter/widgets/finance/saude_financeira_section.dart';

void main() {
  group('SaudeFinanceiraModel - Testes de Cálculo e Benchmarking FGV', () {
    test('Calcula Liquidez, ROE e Score de Saúde com valores positivos', () {
      final model = SaudeFinanceiraModel.calcular(
        saldoAtual: 50000,
        aReceber: 30000,
        aPagar: 20000,
        receitasMes: 40000,
        despesasMes: 25000,
        inadimplenciaPerc: 2.5,
      );

      // Liquidez Corrente = (50000 + 30000) / 20000 = 4.0
      expect(model.liquidezCorrente, closeTo(4.0, 0.01));

      // Margem Líquida = ((40000 - 25000) / 40000) * 100 = 37.5%
      expect(model.margemLiquida, closeTo(37.5, 0.1));

      // ROE deve ser positivo e superior a zero
      expect(model.roe, greaterThan(0));

      // Com liquidez alta e inadimplência baixa, score deve ser Saudável ou Excelente
      expect(model.scoreSaude, greaterThanOrEqualTo(60));
      expect(model.nivelSaude, anyOf('Excelente', 'Saudável'));

      // Verifica presença dos índices FGV
      expect(model.igpmMensal, closeTo(0.45, 0.01));
      expect(model.igpmAcumulado12m, closeTo(3.82, 0.01));
      expect(model.inccMensal, closeTo(0.38, 0.01));
      expect(model.inccAcumulado12m, closeTo(4.65, 0.01));

      // Projeções futuras devem ter 6 meses
      expect(model.projecoes.length, equals(6));
      expect(model.projecoes.first.receitaProjetada, greaterThan(0));
      expect(model.projecoes.first.metaAjustadaIgpm, greaterThan(0));
    });

    test('Classifica status de Atenção/Crítico quando liquidez e margem estão baixas', () {
      final model = SaudeFinanceiraModel.calcular(
        saldoAtual: 1000,
        aReceber: 2000,
        aPagar: 15000,
        receitasMes: 5000,
        despesasMes: 12000,
        inadimplenciaPerc: 18.0,
      );

      // Liquidez < 1.0 (3000 / 15000 = 0.2)
      expect(model.liquidezCorrente, lessThan(1.0));

      // Margem negativa
      expect(model.margemLiquida, lessThan(0));

      // Score de saúde deve ser baixo
      expect(model.scoreSaude, lessThan(50));
      expect(model.nivelSaude, anyOf('Atenção', 'Crítico'));
    });
  });

  group('SaudeFinanceiraSection - Widget Test', () {
    testWidgets('Renderiza cards de diagnóstico, índices FGV e projeções',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = SaudeFinanceiraModel.calcular(
        saldoAtual: 45000,
        aReceber: 25000,
        aPagar: 18000,
        receitasMes: 35000,
        despesasMes: 22000,
        inadimplenciaPerc: 3.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SaudeFinanceiraSection(model: model),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica título principal da seção
      expect(find.text('Saúde Financeira & Indicadores de Mercado (FGV)'),
          findsOneWidget);

      // Verifica cards de métricas
      expect(find.text('Score de Saúde'), findsOneWidget);
      expect(find.text('ROE (Rentabilidade)'), findsOneWidget);
      expect(find.text('Liquidez Corrente'), findsOneWidget);
      expect(find.text('Índices FGV & Mercado'), findsOneWidget);

      // Verifica menção aos índices da FGV
      expect(find.text('IGP-M (FGV)'), findsOneWidget);
      expect(find.text('INCC (FGV)'), findsOneWidget);

      // Verifica título do gráfico de projeções semestrais
      expect(find.text('Projeção Financeira Semestral x Meta IGP-M (FGV)'),
          findsOneWidget);

      // Verifica diretrizes estratégicas
      expect(find.text('Diretrizes Estratégicas para o Gestor'), findsOneWidget);
    });

    testWidgets('Renderiza versão compacta para Mobile sem estourar layout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final model = SaudeFinanceiraModel.calcular(
        saldoAtual: 20000,
        aReceber: 15000,
        aPagar: 10000,
        receitasMes: 20000,
        despesasMes: 15000,
        inadimplenciaPerc: 4.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SaudeFinanceiraSection(
                model: model,
                isCompact: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saúde Financeira & Indicadores de Mercado (FGV)'),
          findsOneWidget);
      expect(find.text('Score de Saúde'), findsOneWidget);
      expect(find.text('ROE (Rentabilidade)'), findsOneWidget);
    });
  });
}
