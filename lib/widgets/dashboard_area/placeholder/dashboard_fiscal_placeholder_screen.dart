import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../services/dashboard_fiscal_caller.dart';
import '../dashboard_area_scaffold.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';

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
  DateTime? _periodoInicio;
  DateTime? _periodoFim;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());
    final resposta = await DashboardFiscalCaller().fetchKpis(
      periodoInicio: _periodoInicio,
      periodoFim: _periodoFim,
    );
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

  String get _periodoLabel {
    if (_periodoInicio == null || _periodoFim == null) return 'Mes atual';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(_periodoInicio!)} - ${fmt(_periodoFim!)}';
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year + 2),
      initialDateRange: DateTimeRange(
        start: _periodoInicio ?? DateTime(agora.year, agora.month, 1),
        end: _periodoFim ?? DateTime(agora.year, agora.month + 1, 0),
      ),
    );
    if (range != null) {
      setState(() {
        _periodoInicio = range.start;
        _periodoFim = range.end;
      });
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Fiscal')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _selecionarPeriodo,
                icon: const Icon(Icons.date_range),
                label: Text(_periodoLabel),
              ),
            ),
          ),
          Expanded(
            child: DashboardAreaScaffold(
              titulo: 'Dashboard Fiscal',
              state: _state,
              periodoInicio: _periodoInicio,
              periodoFim: _periodoFim,
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
