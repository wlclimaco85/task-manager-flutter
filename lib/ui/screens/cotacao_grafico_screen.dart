import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';
import 'package:task_manager_flutter/data/models/grafico_LineChartData.dart';

class CotacaoScreen extends StatefulWidget {
  @override
  _CotacaoScreenState createState() => _CotacaoScreenState();
}

class _CotacaoScreenState extends State<CotacaoScreen> {
  List<Cotacao> cotacoes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    CotacaoCaller().fetchCotacoes().then((data) {
      setState(() {
        cotacoes = data;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Última cotação
    Cotacao ultimaCotacao = cotacoes.last;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico de Cotações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Última Cotação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Data: ${ultimaCotacao.dtCotacao?.day}/${ultimaCotacao.dtCotacao?.month}/${ultimaCotacao.dtCotacao?.year}',
                    style: TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Valor: R\$ ${ultimaCotacao.valor?.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: CotacaoChart(cotacoes: cotacoes),
            ),
          ],
        ),
      ),
    );
  }
}

/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cotações'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Cotações de Ações',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: SideTitles(showTitles: true),
                          bottomTitles: SideTitles(showTitles: true),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: cotacoes.length.toDouble() - 1,
                        minY: 0,
                        maxY: cotacoes
                            .map((c) => c.valor!)
                            .reduce((a, b) => a > b ? a : b),
                        lineBarsData: [
                          LineChartBarData(
                            spots: cotacoes.asMap().entries.map((entry) {
                              int index = entry.key;
                              Cotacao cotacao = entry.value;
                              return FlSpot(index.toDouble(), cotacao.valor!);
                            }).toList(),
                            isCurved: true,
                            colors: [Colors.blue],
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  } */

