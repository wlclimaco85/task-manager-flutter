import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/data/utils/grid_colors.dart';

class ChatDailyPoint {
  final DateTime date;
  final int count;
  ChatDailyPoint(this.date, this.count);

  factory ChatDailyPoint.fromJson(Map<String, dynamic> j) {
    return ChatDailyPoint(DateTime.parse(j['date']), j['count']);
  }
}

class ChatsDailyChart extends StatefulWidget {
  final String baseUrl;
  final int empresaId;
  final int? parceiroId;
  final int days;
  const ChatsDailyChart({
    super.key,
    required this.baseUrl,
    required this.empresaId,
    this.parceiroId,
    this.days = 7,
  });

  @override
  State<ChatsDailyChart> createState() => _ChatsDailyChartState();
}

class _ChatsDailyChartState extends State<ChatsDailyChart> {
  List<ChatDailyPoint> data = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse('${widget.baseUrl}/api/dashboard/chats/daily')
          .replace(queryParameters: {
        'days': widget.days.toString(),
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
      });

      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final arr = jsonDecode(res.body) as List;
      setState(() {
        data = arr.map((e) => ChatDailyPoint.fromJson(e)).toList();
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
      return const SizedBox(
        height: 230,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 230,
        child: Center(
          child: Text(error!,
              style: const TextStyle(color: Colors.red, fontSize: 14)),
        ),
      );
    }

    if (data.isEmpty) {
      return const SizedBox(
        height: 230,
        child: Center(
          child: Text(
            'Nenhum dado de chat nos últimos dias.',
            style: TextStyle(color: GridColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final d = data[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                          fontSize: 10, color: GridColors.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: GridColors.secondary,
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].count.toDouble()),
              ],
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    GridColors.secondary.withOpacity(0.3),
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
