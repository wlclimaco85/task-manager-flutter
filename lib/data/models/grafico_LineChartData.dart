import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';

class CotacaoChart extends StatelessWidget {
  final List<Cotacao> cotacoes;

  const CotacaoChart({Key? key, required this.cotacoes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < cotacoes.length) {
                  return Text(
                    '${cotacoes[index].dtCotacao?.day}/${cotacoes[index].dtCotacao?.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.blue, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: cotacoes.asMap().entries.map((entry) {
              int index = entry.key;
              Cotacao cotacao = entry.value;
              return FlSpot(index.toDouble(), cotacao.valor ?? 0);
            }).toList(),
            isCurved: true,
            color: Colors.blue, // Atualização da cor
            dotData: FlDotData(show: true), // Mostrar pontos
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: cotacoes.length.toDouble() - 1,
        minY: 0,
        maxY: cotacoes.map((c) => c.valor ?? 0).reduce((a, b) => a > b ? a : b),
      ),
    );
  }
}
