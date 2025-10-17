// lib/dashboard/dashboard_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/dashboard_model.dart';
import 'package:task_manager_flutter/data/services/dashboard_caller.dart';
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<FinancePoint> finance = [];
  TicketStatusCounts? tickets;
  List<ChatsDailyPoint> chats = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        DashboardApiClient().fetchFinanceSeries(months: 6),
        DashboardApiClient().fetchTicketStatusCounts(),
        DashboardApiClient().fetchChatsDaily(days: 7),
      ]);
      setState(() {
        finance = results[0] as List<FinancePoint>;
        tickets = results[1] as TicketStatusCounts;
        chats = results[2] as List<ChatsDailyPoint>;
        loading = false;
      });
    } catch (e) {
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
          child: Text(
            error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
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
            _sectionTitle('📊 Financeiro'),
            const SizedBox(height: 8),
            _financeCards(),
            const SizedBox(height: 16),
            _financeChart(),
            const SizedBox(height: 28),
            _sectionTitle('📞 Chamados'),
            const SizedBox(height: 8),
            _ticketsCards(),
            const SizedBox(height: 16),
            _ticketsPie(),
            const SizedBox(height: 28),
            _sectionTitle('💬 Chats (últimos 7 dias)'),
            const SizedBox(height: 8),
            _chatsLine(),
            const SizedBox(height: 20),
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
          color: color.withOpacity(0.1),
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

  Widget _financeCards() {
    final last = finance.isNotEmpty ? finance.last : FinancePoint('—', 0, 0);
    final saldo = last.receivable - last.payable;
    return Row(
      children: [
        _infoCard('A Receber', 'R\$ ${last.receivable.toStringAsFixed(2)}',
            Colors.green),
        _infoCard(
            'A Pagar', 'R\$ ${last.payable.toStringAsFixed(2)}', Colors.red),
        _infoCard(
            'Saldo', 'R\$ ${saldo.toStringAsFixed(2)}', GridColors.primary),
      ],
    );
  }

  Widget _financeChart() {
    final display = List<FinancePoint>.from(finance);
    while (display.length < 6) {
      display.insert(0, FinancePoint('—', 0, 0));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 230,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= display.length) {
                    return const SizedBox.shrink();
                  }
                  final label = display[i].month.length >= 7
                      ? display[i].month.substring(5, 7)
                      : display[i].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: GridColors.textSecondary)),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            for (int i = 0; i < display.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 6,
                barRods: [
                  BarChartRodData(
                      toY: display[i].receivable,
                      color: Colors.green,
                      width: 8),
                  BarChartRodData(
                      toY: display[i].payable, color: Colors.red, width: 8),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _ticketsCards() {
    final t = tickets!;
    return Row(
      children: [
        _infoCard('Abertos', t.open.toString(), Colors.orange),
        _infoCard('Em Andamento', t.inProgress.toString(), Colors.blue),
        _infoCard('Fechados', t.closed.toString(), Colors.green),
      ],
    );
  }

  Widget _ticketsPie() {
    final t = tickets!;
    final total = (t.open + t.inProgress + t.closed).clamp(1, 1 << 31);
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
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    GridColors.secondary.withOpacity(0.4),
                    Colors.transparent
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
