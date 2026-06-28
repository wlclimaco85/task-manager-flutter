import 'package:flutter/material.dart';
import '../../../models/kpi_dashboard_model.dart';
import '../../../models/tendencia_horas_extras_model.dart';
import '../../../services/dashboard_dp_area_caller.dart';
import '../../../utils/grid_colors.dart';
import '../dashboard_area_scaffold.dart';
import '../dashboard_state.dart';
import '../drill_down_router.dart';

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
  List<TendenciaHorasExtrasModel> _horasExtras = [];
  DateTime? _periodoInicio;
  DateTime? _periodoFim;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _state = const DashboardAreaState.loading());

    // Carregar KPIs e tendência em paralelo
    final caller = DashboardDpAreaCaller();
    final kpisResponses = await Future.wait([
      caller.fetchKpis(periodoInicio: _periodoInicio, periodoFim: _periodoFim),
      caller.fetchHorasExtras(),
    ]);

    if (!mounted) return;

    final resposta = kpisResponses[0] as DashboardAreaResponseModel?;
    final horasExtras = kpisResponses[1] as List<TendenciaHorasExtrasModel>?;

    if (resposta == null) {
      setState(() => _state =
          const DashboardAreaState.erro('Nao foi possivel carregar os dados.'));
      return;
    }
    if (resposta.kpis.isEmpty) {
      setState(() => _state = const DashboardAreaState.vazio());
      return;
    }

    setState(() {
      _state = DashboardAreaState.sucesso(resposta.kpis);
      _horasExtras = horasExtras ?? [];
    });
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
      appBar: AppBar(title: const Text('Dashboard Departamento Pessoal')),
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // KPIs em grid
                  DashboardAreaScaffold(
                    titulo: 'Dashboard Departamento Pessoal',
                    state: _state,
                    periodoInicio: _periodoInicio,
                    periodoFim: _periodoFim,
                    onKpiTap: (periodoInicio, periodoFim, drillDownRota) =>
                        DrillDownRouter.navigate(
                            context, drillDownRota, periodoInicio, periodoFim),
                    onRetry: _carregar,
                  ),
                  // Gráfico de horas extras (6 meses)
                  if (_horasExtras.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildGraficoHorasExtras(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gráfico de barras simples (6 meses horas extras).
  Widget _buildGraficoHorasExtras() {
    final maxValor = _horasExtras
        .fold<double>(0, (max, e) => e.valor > max ? e.valor : max);
    final escala = maxValor > 0 ? 1.0 / maxValor : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tendência de Horas Extras (6 meses)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _horasExtras.map((item) {
                  final altura = item.valor * escala * 150; // altura máxima 150px
                  final mes = item.mes.split('-')[1]; // extrai mês de "2026-01"
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Barra
                        Container(
                          width: double.infinity,
                          height: altura,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: GridColors.secondary, // Verde institucional
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Label mês
                        Text(
                          mes,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Legenda valor máximo
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Máx: ${maxValor.toStringAsFixed(1)}h',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
