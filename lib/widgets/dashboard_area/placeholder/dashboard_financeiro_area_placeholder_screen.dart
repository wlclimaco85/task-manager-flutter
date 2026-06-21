import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../services/dashboard_financeiro_area_caller.dart';
import '../dashboard_area_scaffold.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';

/// Screen-casca leve do dashboard de área Financeiro (Fase 171 — fundação).
/// Reaproveitada idêntica nos 3 form factors (mesmo padrão de
/// HidratacaoScreen) — toda a lógica de loading/vazio/erro/grid vive em
/// DashboardAreaScaffold, esta classe só busca o dado e monta o Scaffold/AppBar.
class DashboardFinanceiroAreaPlaceholderScreen extends StatefulWidget {
  const DashboardFinanceiroAreaPlaceholderScreen({super.key});

  @override
  State<DashboardFinanceiroAreaPlaceholderScreen> createState() =>
      _DashboardFinanceiroAreaPlaceholderScreenState();
}

class _DashboardFinanceiroAreaPlaceholderScreenState
    extends State<DashboardFinanceiroAreaPlaceholderScreen> {
  DashboardAreaState<List<KpiDashboardModel>> _state =
      const DashboardAreaState.loading();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());
    final resposta = await DashboardFinanceiroAreaCaller().fetchKpis();
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
      appBar: AppBar(title: const Text('Dashboard Financeiro (Área)')),
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
              titulo: 'Dashboard Financeiro (Área)',
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
