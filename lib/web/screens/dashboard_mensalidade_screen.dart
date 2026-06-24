import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/dashboard_mensalidade_caller.dart';
import '../../utils/grid_colors.dart';

class WebDashboardMensalidadeScreen extends StatefulWidget {
  const WebDashboardMensalidadeScreen({super.key});

  @override
  State<WebDashboardMensalidadeScreen> createState() =>
      _WebDashboardMensalidadeScreenState();
}

class _WebDashboardMensalidadeScreenState
    extends State<WebDashboardMensalidadeScreen> {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _caller = DashboardMensalidadeCaller();

  bool _loading = true;
  bool _baixandoPdf = false;
  String? _erro;
  Map<String, dynamic>? _kpis;

  DateTime _mesInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _mesFim =
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  String get _mesInicioStr =>
      '${_mesInicio.year}-${_mesInicio.month.toString().padLeft(2, '0')}';
  String get _mesFimStr =>
      '${_mesFim.year}-${_mesFim.month.toString().padLeft(2, '0')}';
  String get _periodoLabel =>
      '${_mesInicio.month.toString().padLeft(2, '0')}/${_mesInicio.year}'
      ' a '
      '${_mesFim.month.toString().padLeft(2, '0')}/${_mesFim.year}';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final dados = await _caller.fetchKpis(
        mesInicio: _mesInicioStr, mesFim: _mesFimStr);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _kpis = dados;
      if (dados == null) _erro = 'Não foi possível carregar os dados.';
    });
  }

  Future<void> _baixarPdf() async {
    setState(() => _baixandoPdf = true);
    try {
      final bytes = await _caller.baixarPdf(
          mesInicio: _mesInicioStr, mesFim: _mesFimStr);
      if (bytes == null || !mounted) return;

      if (kIsWeb) {
        // No web, usa download via anchor element (feito por NetworkCaller padrão)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado. Verifique os downloads.')),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/mensalidades_${_mesInicioStr}_${_mesFimStr}.pdf');
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF salvo em ${file.path}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _baixandoPdf = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year + 2),
      initialDateRange:
          DateTimeRange(start: _mesInicio, end: _mesFim),
      locale: const Locale('pt', 'BR'),
    );
    if (range != null) {
      setState(() {
        _mesInicio = DateTime(range.start.year, range.start.month, 1);
        _mesFim =
            DateTime(range.end.year, range.end.month + 1, 0);
      });
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Mensalidades'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _selecionarPeriodo,
            icon: const Icon(Icons.date_range, color: Colors.white),
            label: Text(_periodoLabel,
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _baixandoPdf ? null : _baixarPdf,
            icon: _baixandoPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Relatório PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_kpis == null) {
      return const Center(child: Text('Sem dados para o período.'));
    }

    final total = _kpis!['totalGerado'] ?? 0.0;
    final pago = _kpis!['totalPago'] ?? 0.0;
    final atrasado = _kpis!['totalAtrasado'] ?? 0.0;
    final pendente = _kpis!['totalPendente'] ?? 0.0;
    final parceirosPagos = _kpis!['parceirosPagos'] ?? 0;
    final parceirosAtrasados = _kpis!['parceirosAtrasados'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Período: $_periodoLabel',
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _kpiCard('Total Gerado', total, Colors.blueGrey, Icons.receipt_long),
              _kpiCard('Pago', pago, GridColors.secondary, Icons.check_circle),
              _kpiCard('Atrasado', atrasado, Colors.red.shade700,
                  Icons.warning_rounded),
              _kpiCard('Pendente', pendente, Colors.orange.shade700,
                  Icons.schedule),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              _contadorCard(
                  'Pagantes', parceirosPagos.toString(), GridColors.secondary),
              const SizedBox(width: 12),
              _contadorCard('Inadimplentes', parceirosAtrasados.toString(),
                  Colors.red.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
      String label, dynamic valor, Color cor, IconData icone) {
    final v = valor is num ? valor.toDouble() : 0.0;
    return Card(
      elevation: 2,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cor))),
            ]),
            const SizedBox(height: 8),
            Text(_currency.format(v),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }

  Widget _contadorCard(String label, String valor, Color cor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cor)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
