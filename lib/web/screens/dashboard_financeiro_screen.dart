import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/dashboard_financeiro_caller.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/empresa_caller.dart';
import '../../utils/utils.dart';

class WebDashboardFinanceiroScreen extends StatefulWidget {
  const WebDashboardFinanceiroScreen({super.key});

  @override
  State<WebDashboardFinanceiroScreen> createState() =>
      _WebDashboardFinanceiroScreenState();
}

class _WebDashboardFinanceiroScreenState
    extends State<WebDashboardFinanceiroScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _contasBancarias = [];

  int? _empresaId;
  int? _contaBancariaId;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  double _aPagar = 0;
  double _aReceber = 0;
  double _saldoProjetado = 0;
  double _totalVencido = 0;

  List<_FluxoItem> _fluxo = [];
  List<_CategoriaItem> _categorias = [];
  List<_ParceiroItem> _topParceiros = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    _empresas = await EmpresaCaller.loadEmpresas();
    _contasBancarias = await ContaBancariaCaller.loadContas();
    _empresaId = pegarEmpresaLogada();
    if (_empresas.length == 1) _empresaId = _empresas.first['value'] as int?;
    if (!mounted) return;
    setState(() {});
    await _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await DashboardFinanceiroCaller().obterDashboard(
        empresaId: _empresaId,
        contaBancariaId: _contaBancariaId,
        dataInicio: _dataInicio?.toIso8601String().split('T').first,
        dataFim: _dataFim?.toIso8601String().split('T').first,
      );

      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Nenhum dado encontrado';
        });
        return;
      }

      final body = data['data'] is Map ? data['data'] : data;

      setState(() {
        _aPagar = _toDouble(body['aPagar'] ?? body['totalAPagar'] ?? 0);
        _aReceber = _toDouble(body['aReceber'] ?? body['totalAReceber'] ?? 0);
        _saldoProjetado =
            _toDouble(body['saldoProjetado'] ?? body['saldo'] ?? 0);
        _totalVencido =
            _toDouble(body['totalVencido'] ?? body['vencido'] ?? 0);

        _fluxo = _parseFluxo(body['fluxoCaixaProjetado'] ?? body['fluxo'] ?? []);
        _categorias = _parseCategorias(
            body['categorias'] ?? body['categoriasFinanceiras'] ?? []);
        _topParceiros = _parseParceiros(
            body['topParceiros'] ?? body['topClientes'] ?? body['topFornecedores'] ?? []);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao carregar dashboard: $e';
      });
    }
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  List<_FluxoItem> _parseFluxo(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _FluxoItem('', 0, 0);
      return _FluxoItem(
        e['semana']?.toString() ?? e['label']?.toString() ?? '',
        _toDouble(e['entrada'] ?? e['receber'] ?? 0),
        _toDouble(e['saida'] ?? e['pagar'] ?? 0),
      );
    }).toList();
  }

  List<_CategoriaItem> _parseCategorias(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _CategoriaItem('', 0);
      return _CategoriaItem(
        e['nome']?.toString() ?? e['descricao']?.toString() ?? '',
        _toDouble(e['valor'] ?? 0),
      );
    }).toList();
  }

  List<_ParceiroItem> _parseParceiros(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is! Map) return _ParceiroItem('', 0);
      return _ParceiroItem(
        e['nome']?.toString() ?? '',
        _toDouble(e['valor'] ?? e['total'] ?? 0),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Financeiro Gerencial')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadDashboard, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltros(),
          const SizedBox(height: 16),
          _buildKpiCards(),
          const SizedBox(height: 24),
          _buildFluxoChart(),
          const SizedBox(height: 24),
          _buildPieCharts(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (_empresas.isNotEmpty)
              _dropdown(
                value: _empresaId,
                items: _empresas,
                hint: 'Empresa',
                onChanged: (v) {
                  _empresaId = v;
                  _loadDashboard();
                },
              ),
            if (_contasBancarias.isNotEmpty)
              _dropdown(
                value: _contaBancariaId,
                items: _contasBancarias,
                hint: 'Conta Bancária',
                onChanged: (v) {
                  _contaBancariaId = v;
                  _loadDashboard();
                },
              ),
            _dateField(
              label: 'Data Início',
              selected: _dataInicio,
              onPick: (d) {
                _dataInicio = d;
                _loadDashboard();
              },
              onClear: () {
                _dataInicio = null;
                _loadDashboard();
              },
            ),
            _dateField(
              label: 'Data Fim',
              selected: _dataFim,
              onPick: (d) {
                _dataFim = d;
                _loadDashboard();
              },
              onClear: () {
                _dataFim = null;
                _loadDashboard();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required ValueChanged<int?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text('Todos', style: TextStyle(color: Colors.grey[500])),
          ),
          ...items.map((e) => DropdownMenuItem<int>(
                value: e['value'] as int?,
                child: Text(e['label']?.toString() ?? ''),
              )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? selected,
    required ValueChanged<DateTime?> onPick,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          suffixIcon: selected != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          selected != null
              ? DateFormat('dd/MM/yyyy').format(selected)
              : 'Selecionar',
          style: TextStyle(
              color: selected != null ? Colors.black : Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildKpiCards() {
    final kpis = [
      _KpiData('A Pagar', _aPagar, Colors.red.shade700, Icons.arrow_upward),
      _KpiData('A Receber', _aReceber, Colors.green.shade700, Icons.arrow_downward),
      _KpiData('Saldo Projetado', _saldoProjetado, Colors.blue.shade700, Icons.account_balance),
      _KpiData('Vencido', _totalVencido, Colors.orange.shade700, Icons.warning),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildKpiCard(kpis[i]),
      ),
    );
  }

  Widget _buildKpiCard(_KpiData kpi) {
    final color = kpi.color;
    final isNegative = kpi.valor < 0 && kpi.label != 'Saldo Projetado';
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(kpi.icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(kpi.label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _currency.format(kpi.valor),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isNegative ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluxoChart() {
    if (_fluxo.isEmpty) {
      return Card(
        child: Container(
          height: 280,
          alignment: Alignment.center,
          child: Text('Nenhum dado de fluxo de caixa disponível',
              style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fluxo de Caixa Projetado',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 8),
            Row(
              children: [
                _legenda(Colors.green, 'Entrada'),
                const SizedBox(width: 16),
                _legenda(Colors.red, 'Saída'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _fluxoMaxY(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gIndex, rod, rIndex) {
                        final item = _fluxo[gIndex];
                        final label = rIndex == 0 ? 'Entrada' : 'Saída';
                        return BarTooltipItem(
                          '${item.semana}\n$label: ${_currency.format(rod.toY)}',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _currency.format(value).replaceAll('R\$', ''),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= _fluxo.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_fluxo[i].semana,
                                style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _fluxo.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: item.entrada,
                          color: Colors.green,
                          width: 14,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: item.saida,
                          color: Colors.red,
                          width: 14,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _fluxoMaxY() {
    double max = 0;
    for (final f in _fluxo) {
      if (f.entrada > max) max = f.entrada;
      if (f.saida > max) max = f.saida;
    }
    return max * 1.2;
  }

  Widget _legenda(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPieCharts() {
    if (_categorias.isEmpty && _topParceiros.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (_categorias.isNotEmpty)
          Expanded(child: _buildPieChartCard('Categorias Financeiras', _categorias.map((c) => _PieData(c.nome, c.valor)).toList())),
        if (_categorias.isNotEmpty && _topParceiros.isNotEmpty)
          const SizedBox(width: 16),
        if (_topParceiros.isNotEmpty)
          Expanded(child: _buildPieChartCard('Top Parceiros', _topParceiros.map((p) => _PieData(p.nome, p.valor)).toList())),
      ],
    );
  }

  Widget _buildPieChartCard(String title, List<_PieData> data) {
    final total = data.fold<double>(0, (s, d) => s + d.valor);
    if (total == 0) return const SizedBox.shrink();

    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.cyan, Colors.amber,
      Colors.indigo, Colors.pink,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: data.asMap().entries.map((e) {
                          final i = e.key;
                          final d = e.value;
                          final pct = (d.valor / total) * 100;
                          return PieChartSectionData(
                            value: d.valor,
                            title: '${pct.toStringAsFixed(1)}%',
                            color: colors[i % colors.length],
                            radius: 60,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.asMap().entries.map((e) {
                      final i = e.key;
                      final d = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[i % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${d.nome}: ${_currency.format(d.valor)}',
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final double valor;
  final Color color;
  final IconData icon;
  _KpiData(this.label, this.valor, this.color, this.icon);
}

class _FluxoItem {
  final String semana;
  final double entrada;
  final double saida;
  _FluxoItem(this.semana, this.entrada, this.saida);
}

class _CategoriaItem {
  final String nome;
  final double valor;
  _CategoriaItem(this.nome, this.valor);
}

class _ParceiroItem {
  final String nome;
  final double valor;
  _ParceiroItem(this.nome, this.valor);
}

class _PieData {
  final String nome;
  final double valor;
  _PieData(this.nome, this.valor);
}
