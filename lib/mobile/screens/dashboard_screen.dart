import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/conta_model.dart';
import '../../models/dashboard_model.dart';
import '../../services/conta_caller.dart';
import '../../services/dashboard_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/utils.dart';
import '../screens/chats_daily_chart.dart';
import '../screens/dashboard_alerts_screen.dart';
import '../screens/dashboard_client_distribution_screen.dart';
import '../screens/dashboard_conta_evolucao_screen.dart';
import '../screens/dashboard_contas_balances_screen.dart';
import '../screens/dashboard_finance_fluxo_diario_screen.dart';
import '../screens/dashboard_finance_trend_screen.dart';
import '../screens/dashboard_kpis_screen.dart';
import '../screens/dashboard_quarterly_screen.dart';
import '../screens/dashboard_tickets_trend_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final int empresaId = pegarEmpresaLogada() ?? 0;
  final int? parceiroId = pegarParceiroLogada();

  List<FinanceFluxoPoint> fluxoDiario = [];
  List<ContaBancariaModel> contas = [];
  TicketStatusCounts? tickets;
  List<ChatsDailyPoint> chats = [];
  bool loading = true;
  String? error;

  ContaBancariaModel? get _contaPrincipal {
    if (contas.isEmpty) return null;
    final ordered = [...contas]
      ..sort((a, b) => b.saldo.abs().compareTo(a.saldo.abs()));
    return ordered.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    Future<List<FinanceFluxoPoint>> fluxoF() async {
      try {
        return await DashboardApiClient().fetchFinanceFluxoDiario(
          daysBack: 10,
          daysForward: 30,
        );
      } catch (_) {
        return [];
      }
    }

    Future<List<ContaBancariaModel>> contasF() async {
      try {
        return await ContaApi().listarSaldos();
      } catch (_) {
        return [];
      }
    }

    Future<TicketStatusCounts> ticketF() async {
      try {
        return await DashboardApiClient().fetchTicketStatusCounts();
      } catch (_) {
        return TicketStatusCounts(open: 0, inProgress: 0, closed: 0);
      }
    }

    Future<List<ChatsDailyPoint>> chatsF() async {
      try {
        return await DashboardApiClient().fetchChatsDaily(days: 7);
      } catch (_) {
        return [];
      }
    }

    try {
      final results = await Future.wait([
        fluxoF(),
        contasF(),
        ticketF(),
        chatsF(),
      ], eagerError: false);

      if (!mounted) return;
      setState(() {
        fluxoDiario = results[0] as List<FinanceFluxoPoint>;
        contas = results[1] as List<ContaBancariaModel>;
        tickets = results[2] as TicketStatusCounts;
        chats = results[3] as List<ChatsDailyPoint>;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Indicadores-chave'),
            const SizedBox(height: 8),
            KpiCards(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Fluxo de caixa gerencial'),
            const SizedBox(height: 8),
            _cashSummaryCards(),
            const SizedBox(height: 16),
            FinanceFluxoDiarioChart(data: fluxoDiario),
            const SizedBox(height: 12),
            _cashHighlights(),
            const SizedBox(height: 28),
            _sectionTitle('Tendência financeira'),
            const SizedBox(height: 8),
            FinanceTrendChart(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Saldos bancários'),
            const SizedBox(height: 8),
            const ContasBalancesChart(),
            if (_contaPrincipal != null) ...[
              const SizedBox(height: 20),
              _sectionTitle('Evolução da principal conta'),
              const SizedBox(height: 8),
              ContaEvolucaoChart(conta: _contaPrincipal!),
            ],
            const SizedBox(height: 28),
            _sectionTitle('Distribuição por clientes'),
            const SizedBox(height: 8),
            ClientDistributionPie(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Comparativo trimestral'),
            const SizedBox(height: 8),
            QuarterlyBars(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Alertas de vencimentos'),
            const SizedBox(height: 8),
            AlertsPanel(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Chamados'),
            const SizedBox(height: 8),
            _ticketsCards(),
            const SizedBox(height: 16),
            _ticketsPie(),
            const SizedBox(height: 28),
            _sectionTitle('Tendência de chamados'),
            const SizedBox(height: 8),
            TicketsTrendChart(
              empresaId: empresaId,
              parceiroId: parceiroId,
              months: 6,
            ),
            const SizedBox(height: 28),
            _sectionTitle('Chats'),
            const SizedBox(height: 8),
            _chatsLine(),
            const SizedBox(height: 28),
            _sectionTitle('Atividade diária de chats'),
            const SizedBox(height: 8),
            ChatsDailyChart(
              empresaId: empresaId,
              parceiroId: parceiroId,
              days: 7,
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GridColors.textSecondary,
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: GridColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cashSummaryCards() {
    final entradaPrevista = fluxoDiario.fold<double>(
      0,
      (sum, item) => sum + item.receivable,
    );
    final saidaPrevista = fluxoDiario.fold<double>(
      0,
      (sum, item) => sum + item.payable,
    );
    final saldoProjetado = entradaPrevista - saidaPrevista;

    return Row(
      children: [
        _infoCard('Entradas', _currency.format(entradaPrevista), Colors.green),
        _infoCard('Saídas', _currency.format(saidaPrevista), Colors.red),
        _infoCard(
          'Saldo projetado',
          _currency.format(saldoProjetado),
          saldoProjetado >= 0 ? GridColors.primary : Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _cashHighlights() {
    if (fluxoDiario.isEmpty) {
      return const Text(
        'Ainda não há dados suficientes para destacar melhor dia de entrada e maior pressão de saída.',
        style: TextStyle(color: GridColors.textSecondary),
      );
    }

    final maiorEntrada = fluxoDiario.reduce(
      (a, b) => a.receivable >= b.receivable ? a : b,
    );
    final maiorSaida = fluxoDiario.reduce(
      (a, b) => a.payable >= b.payable ? a : b,
    );
    final piorSaldo = fluxoDiario.reduce(
      (a, b) => a.net <= b.net ? a : b,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _highlightCard(
          'Melhor entrada',
          '${DateFormat('dd/MM').format(maiorEntrada.day)} • ${_currency.format(maiorEntrada.receivable)}',
          Colors.green,
        ),
        _highlightCard(
          'Maior saída',
          '${DateFormat('dd/MM').format(maiorSaida.day)} • ${_currency.format(maiorSaida.payable)}',
          Colors.red,
        ),
        _highlightCard(
          'Pior saldo diário',
          '${DateFormat('dd/MM').format(piorSaldo.day)} • ${_currency.format(piorSaldo.net)}',
          piorSaldo.net >= 0 ? GridColors.primary : Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _highlightCard(String title, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _ticketsCards() {
    final t = tickets!;
    return Row(
      children: [
        _infoCard('Abertos', t.open.toString(), Colors.orange),
        _infoCard('Em andamento', t.inProgress.toString(), Colors.blue),
        _infoCard('Fechados', t.closed.toString(), Colors.green),
      ],
    );
  }

  Widget _ticketsPie() {
    final t = tickets!;
    final total = math.max((t.open + t.inProgress + t.closed).toDouble(), 1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: t.open / total,
              color: Colors.orange,
              title: 'Abertos',
            ),
            PieChartSectionData(
              value: t.inProgress / total,
              color: Colors.blue,
              title: 'Andamento',
            ),
            PieChartSectionData(
              value: t.closed / total,
              color: Colors.green,
              title: 'Fechados',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatsLine() {
    final points = chats;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 230,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: GridColors.secondary,
              spots: [
                for (int i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].openChats.toDouble()),
              ],
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    GridColors.secondary.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
