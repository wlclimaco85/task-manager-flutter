import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../services/dashboard_dp_area_caller.dart';
import '../dashboard_area_scaffold.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';

/// Screen-casca leve do dashboard de área DP (Fase 171 — fundação).
class DashboardDpAreaPlaceholderScreen extends StatefulWidget {
  const DashboardDpAreaPlaceholderScreen({super.key});

  @override
  State<DashboardDpAreaPlaceholderScreen> createState() =>
      _DashboardDpAreaPlaceholderScreenState();
}

class _DashboardDpAreaPlaceholderScreenState
    extends State<DashboardDpAreaPlaceholderScreen> {
  DashboardAreaState<List<KpiDashboardModel>> _state =
      const DashboardAreaState.loading();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());
    final resposta = await DashboardDpAreaCaller().fetchKpis();
    if (!mounted) return;
    if (resposta == null) {
      setState(() => _state =
          const DashboardAreaState.erro('Nao foi possivel carregar os dados.'));
      return;
    }
    if (resposta.kpis.isEmpty) {
      setState(() => _state = const DashboardAreaState.vazio());
      return;
    }
    setState(() => _state = DashboardAreaState.sucesso(resposta.kpis));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard DP (Área)')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Em construção — KPIs desta área chegam em fase futura.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(
            child: DashboardAreaScaffold(
              titulo: 'Dashboard DP (Área)',
              state: _state,
              onKpiTap: (periodoInicio, periodoFim, drillDownRota) =>
                  DrillDownRouter.navigate(
                      context, drillDownRota, periodoInicio, periodoFim),
              onRetry: _carregar,
            ),
          ),
        ],
      ),
    );
  }
}
