import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';
import 'package:task_manager_flutter/data/models/grafico_LineChartData.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:task_manager_flutter/data/models/cotacao_model.dart';
import 'package:task_manager_flutter/data/services/cotacao_caller.dart';

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
    _fetchCotacoes();
  }

  void _fetchCotacoes() {
    setState(() {
      isLoading = true;
    });
    CotacaoCaller().fetchCotacoes().then((data) {
      setState(() {
        cotacoes = data;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico de Cotações'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchCotacoes,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
                        const Text(
                          'Últimas 5 Cotações',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Table(
                          border: TableBorder.all(),
                          columnWidths: const {
                            0: FlexColumnWidth(),
                            1: FlexColumnWidth(),
                          },
                          children: [
                            const TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Data',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'Valor (R\$)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            // Mostra apenas as 5 últimas cotações
                            ...cotacoes.take(5).map((cotacao) {
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '${cotacao.dtCotacao?.day}/${cotacao.dtCotacao?.month}/${cotacao.dtCotacao?.year}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'R\$ ${cotacao.valor?.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Stack(
                      children: [
                        CotacaoChart(cotacoes: cotacoes),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
