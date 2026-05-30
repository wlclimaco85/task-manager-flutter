import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/carteira_models.dart';
import '../services/carteira_repository.dart';

class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> {
  final _repo = CarteiraRepository();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtPct = NumberFormat('+#,##0.00;-#,##0.00', 'pt_BR');

  CarteiraResumo? _carteira;
  bool _loading = true;
  String? _erro;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final c = await _repo.fetchCarteira();
      setState(() { _carteira = c; _loading = false; });
    } catch (e) {
      setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Minha Carteira', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _carregar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: const Color(0xFF00D4FF),
                  child: _buildBody(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaOperacao,
        backgroundColor: const Color(0xFF00D4FF),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nova Operação', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErro() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
      const SizedBox(height: 12),
      Text(_erro!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _carregar, child: const Text('Tentar novamente')),
    ]),
  );

  Widget _buildBody() {
    final c = _carteira!;
    if (c.posicoes.isEmpty) return _buildVazio();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildHeader(c),
        const SizedBox(height: 20),
        if (c.posicoes.length > 1) ...[
          _buildGraficoPizza(c),
          const SizedBox(height: 20),
        ],
        _buildListaPosicoes(c),
      ],
    );
  }

  Widget _buildVazio() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.white24),
      const SizedBox(height: 16),
      const Text('Nenhuma posição', style: TextStyle(color: Colors.white70, fontSize: 18)),
      const SizedBox(height: 8),
      const Text('Adicione sua primeira compra', style: TextStyle(color: Colors.white38)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _abrirNovaOperacao,
        icon: const Icon(Icons.add),
        label: const Text('Nova Operação'),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black),
      ),
    ]),
  );

  Widget _buildHeader(CarteiraResumo c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.ganhoPositivo
              ? [const Color(0xFF0A3D2E), const Color(0xFF0D5C3D)]
              : [const Color(0xFF3D0A0A), const Color(0xFF5C0D0D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.ganhoPositivo ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Valor Atual', style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(_fmt.format(c.valorAtual),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatChip(
            'Ganho Total',
            '${_fmt.format(c.ganhoPerda)} (${_fmtPct.format(c.ganhoPerdaPercent)}%)',
            c.ganhoPositivo,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            'Hoje',
            '${_fmt.format(c.variacaoDiaTotal)} (${_fmtPct.format(c.variacaoDiaTotalPercent)}%)',
            c.variacaoDiaPositiva,
          ),
        ]),
        const SizedBox(height: 8),
        Text('Investido: ${_fmt.format(c.totalInvestido)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _buildStatChip(String label, String value, bool positivo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                color: positivo ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                fontSize: 13, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildGraficoPizza(CarteiraResumo c) {
    final cores = [
      const Color(0xFF00D4FF), const Color(0xFF00E676), const Color(0xFFFFD740),
      const Color(0xFFFF7043), const Color(0xFFAB47BC), const Color(0xFF26C6DA),
      const Color(0xFFEF5350), const Color(0xFF66BB6A),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Alocação', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                pieTouchData: PieTouchData(touchCallback: (e, r) {
                  setState(() => _touchedIndex = r?.touchedSection?.touchedSectionIndex ?? -1);
                }),
                sections: c.posicoes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final isTouched = i == _touchedIndex;
                  return PieChartSectionData(
                    color: cores[i % cores.length],
                    value: p.participacaoCarteira,
                    radius: isTouched ? 80 : 65,
                    title: isTouched ? p.ticker : '',
                    titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: c.posicoes.take(6).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(
                      color: cores[i % cores.length], shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${p.ticker} ${p.participacaoCarteira.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildListaPosicoes(CarteiraResumo c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Posições (${c.posicoes.length})',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('ordenado por participação', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        ...c.posicoes.map((p) => _buildCardPosicao(p)),
      ],
    );
  }

  Widget _buildCardPosicao(PosicaoAcao p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: p.positivo ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(child: Text(p.ticker.substring(0, p.ticker.length.clamp(0, 4)),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.ticker, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(p.nomeAtivo, style: const TextStyle(color: Colors.white54, fontSize: 11),
                overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmt.format(p.valorAtual),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text('${p.participacaoCarteira.toStringAsFixed(1)}% da carteira',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        Row(children: [
          _buildInfoCol('Preço médio', _fmt.format(p.precoMedio)),
          _buildInfoCol('Preço atual',
              p.cotacaoDisponivel ? _fmt.format(p.precoAtual) : '—',
              sub: p.cotacaoDisponivel
                  ? '${_fmtPct.format(p.variacaoDiaPercent)}% hoje'
                  : 'sem cotação',
              subColor: p.variacaoDiaPositiva ? const Color(0xFF00E676) : const Color(0xFFFF5252)),
          _buildInfoCol('Ganho/Perda',
              _fmt.format(p.ganhoPerda),
              sub: '${_fmtPct.format(p.ganhoPerdaPercent)}%',
              subColor: p.positivo ? const Color(0xFF00E676) : const Color(0xFFFF5252)),
          _buildInfoCol('Qtd', p.quantidade % 1 == 0
              ? p.quantidade.toInt().toString()
              : p.quantidade.toStringAsFixed(2)),
        ]),
      ]),
    );
  }

  Widget _buildInfoCol(String label, String value, {String? sub, Color? subColor}) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      if (sub != null)
        Text(sub, style: TextStyle(color: subColor ?? Colors.white54, fontSize: 11)),
    ]));
  }

  void _abrirNovaOperacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NovaOperacaoSheet(
        onSalvo: (_) { Navigator.pop(ctx); _carregar(); },
        repo: _repo,
      ),
    );
  }
}

class _NovaOperacaoSheet extends StatefulWidget {
  final Function(OperacaoAcao) onSalvo;
  final CarteiraRepository repo;
  const _NovaOperacaoSheet({required this.onSalvo, required this.repo});

  @override
  State<_NovaOperacaoSheet> createState() => _NovaOperacaoSheetState();
}

class _NovaOperacaoSheetState extends State<_NovaOperacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tickerCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _corretoraCtrl = TextEditingController();
  final _taxasCtrl = TextEditingController(text: '0');
  String _tipo = 'COMPRA';
  DateTime _data = DateTime.now();
  bool _salvando = false;

  double get _custoTotal {
    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 0;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0;
    final taxas = double.tryParse(_taxasCtrl.text.replaceAll(',', '.')) ?? 0;
    return qtd * preco + taxas;
  }

  @override
  void dispose() {
    _tickerCtrl.dispose(); _qtdCtrl.dispose(); _precoCtrl.dispose();
    _corretoraCtrl.dispose(); _taxasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Nova Operação', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            // Tipo
            Row(children: [
              _tipoBtn('COMPRA', Colors.green),
              const SizedBox(width: 12),
              _tipoBtn('VENDA', Colors.red),
            ]),
            const SizedBox(height: 16),
            // Ticker
            _campo('Ticker (ex: PETR4)', _tickerCtrl,
                validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                onChanged: (v) => _tickerCtrl.value = _tickerCtrl.value.copyWith(text: v.toUpperCase(),
                    selection: TextSelection.collapsed(offset: v.length))),
            const SizedBox(height: 12),
            // Data
            InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context,
                    initialDate: _data, firstDate: DateTime(2000), lastDate: DateTime.now());
                if (d != null) setState(() => _data = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat('dd/MM/yyyy').format(_data), style: const TextStyle(color: Colors.white70)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo('Quantidade', _qtdCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)),
              const SizedBox(width: 12),
              Expanded(child: _campo('Preço (R\$)', _precoCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo('Corretora', _corretoraCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _campo('Taxas (R\$)', _taxasCtrl, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            // Custo total
            ListenableBuilder(
              listenable: Listenable.merge([_qtdCtrl, _precoCtrl, _taxasCtrl]),
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Custo Total', style: TextStyle(color: Colors.white60)),
                  Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(_custoTotal),
                      style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _salvando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Salvar Operação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tipoBtn(String tipo, Color cor) {
    final sel = _tipo == tipo;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? cor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? cor : Colors.white24, width: sel ? 2 : 1)),
        child: Center(child: Text(tipo, style: TextStyle(
            color: sel ? cor : Colors.white54, fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
      ),
    ));
  }

  Widget _campo(String label, TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true, fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00D4FF))),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final op = await widget.repo.adicionarOperacao({
        'ticker': _tickerCtrl.text.toUpperCase().trim(),
        'tipo': _tipo,
        'quantidade': double.parse(_qtdCtrl.text.replaceAll(',', '.')),
        'precoUnitario': double.parse(_precoCtrl.text.replaceAll(',', '.')),
        'dataOperacao': DateFormat('yyyy-MM-dd').format(_data),
        'corretora': _corretoraCtrl.text.isEmpty ? null : _corretoraCtrl.text,
        'taxas': double.tryParse(_taxasCtrl.text.replaceAll(',', '.')) ?? 0,
      });
      widget.onSalvo(op);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
