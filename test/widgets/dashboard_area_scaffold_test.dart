import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_manager_flutter/models/kpi_dashboard_model.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/dashboard_area_scaffold.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/dashboard_state.dart';
import 'package:task_manager_flutter/widgets/dashboard_area/drill_down_router.dart';
import 'package:task_manager_flutter/mobile/screens/conta_pagar_grid_screen.dart';

List<KpiDashboardModel> _kpisFake(int quantidade) => List.generate(
      quantidade,
      (i) => KpiDashboardModel(
        chave: 'kpi$i',
        label: 'KPI $i',
        valor: i.toDouble(),
        drillDownRota: i == 0 ? 'contaPagarGrid' : null,
      ),
    );

Widget _buildScaffold({
  required DashboardAreaState<List<KpiDashboardModel>> state,
  double largura = 800,
  void Function(DateTime?, DateTime?, String?)? onKpiTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: largura,
        child: DashboardAreaScaffold(
          titulo: 'Dashboard de teste',
          state: state,
          onKpiTap: onKpiTap,
        ),
      ),
    ),
  );
}

void main() {
  group('DashboardAreaScaffold — estados', () {
    testWidgets('loading exibe indicador de progresso', (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: const DashboardAreaState.loading(),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('vazio exibe "Nenhum dado encontrado"', (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: const DashboardAreaState.vazio(),
      ));
      expect(find.text('Nenhum dado encontrado'), findsOneWidget);
    });

    testWidgets('erro exibe mensagem de erro', (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: const DashboardAreaState.erro('Falha ao carregar'),
      ));
      expect(find.text('Falha ao carregar'), findsOneWidget);
    });

    testWidgets('sucesso com kpis renderiza KpiCards', (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: DashboardAreaState.sucesso(_kpisFake(3)),
      ));
      expect(find.text('KPI 0'), findsOneWidget);
      expect(find.text('KPI 1'), findsOneWidget);
      expect(find.text('KPI 2'), findsOneWidget);
    });

    testWidgets('sucesso com lista vazia trata como "Nenhum dado encontrado"',
        (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: const DashboardAreaState.sucesso([]),
      ));
      expect(find.text('Nenhum dado encontrado'), findsOneWidget);
    });
  });

  group('DashboardAreaScaffold — responsividade por LayoutBuilder', () {
    testWidgets('largura < 600px renderiza 1 coluna (mobile)', (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: DashboardAreaState.sucesso(_kpisFake(4)),
        largura: 400,
      ));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
    });

    testWidgets('largura entre 600-1200px renderiza 2 colunas (windows)',
        (tester) async {
      await tester.pumpWidget(_buildScaffold(
        state: DashboardAreaState.sucesso(_kpisFake(4)),
        largura: 800,
      ));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('largura >= 1200px renderiza 3+ colunas (web)', (tester) async {
      // Viewport de teste padrao (~800 logicos) e menor que 1200 — expande a
      // superficie real de teste para que o SizedBox(width: 1400) nao seja
      // comprimido pela janela, garantindo LayoutBuilder.constraints.maxWidth
      // >= 1200 de fato.
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildScaffold(
        state: DashboardAreaState.sucesso(_kpisFake(4)),
        largura: 1400,
      ));
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });
  });

  group('DashboardAreaScaffold — drill-down (Tarefa F1b, prova de conceito)',
      () {
    testWidgets(
        'tap em KPI com drillDownRota=contaPagarGrid navega de fato para a tela de contas a pagar',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            key: key,
            width: 800,
            child: DashboardAreaScaffold(
              titulo: 'Dashboard de teste',
              state: DashboardAreaState.sucesso(_kpisFake(1)),
              onKpiTap: (periodoInicio, periodoFim, drillDownRota) {
                DrillDownRouter.navigate(
                  key.currentContext!,
                  drillDownRota,
                  periodoInicio,
                  periodoFim,
                );
              },
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // flutter test roda em ambiente nao-web/nao-windows -> DrillDownRouter
      // resolve para a tela mobile (mesmo padrao condicional de main.dart).
      expect(find.byType(ContaPagarGridScreen), findsNothing);

      await tester.tap(find.text('KPI 0'));
      await tester.pumpAndSettle();

      expect(find.byType(ContaPagarGridScreen), findsOneWidget);
    });
  });
}
