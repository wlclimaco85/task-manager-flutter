import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../services/dashboard_fiscal_caller.dart';
import '../dashboard_area_scaffold.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';

/// Screen-casca leve do dashboard de área Fiscal (Fase 171 — fundação).
class DashboardFiscalPlaceholderScreen extends StatefulWidget {
  const DashboardFiscalPlaceholderScreen({super.key});

  @override
  State<DashboardFiscalPlaceholderScreen> createState() =>
      _DashboardFiscalPlaceholderScreenState();
}

class _DashboardFiscalPlaceholderScreenState
    extends State<DashboardFiscalPlaceholderScreen> {
  DashboardAreaState<List<KpiDashboardModel>> _state =
      const DashboardAreaState.loading();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());
    final resposta = await DashboardFiscalCaller().fetchKpis();
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
      appBar: AppBar(title: const Text('Dashboard Fiscal')),
      body: DashboardAreaScaffold(
        titulo: 'Dashboard Fiscal',
        state: _state,
        onKpiTap: (periodoInicio, periodoFim, drillDownRota) =>
            DrillDownRouter.navigate(
                context, drillDownRota, periodoInicio, periodoFim),
        onRetry: _carregar,
      ),
    );
  }
}
