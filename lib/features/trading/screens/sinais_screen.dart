import 'package:flutter/material.dart';
import '../trading_models.dart';
import '../trading_repository.dart';
import '../../../utils/grid_colors.dart';

class SinaisScreen extends StatefulWidget {
  const SinaisScreen({super.key});
  @override
  State<SinaisScreen> createState() => _SinaisScreenState();
}

class _SinaisScreenState extends State<SinaisScreen> {
  final _repo = TradingRepository();
  List<TradingSignal> _sinais = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sinais = await _repo.fetchSignals();
      if (mounted) setState(() { _sinais = sinais; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao carregar sinais: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinais de Mercado'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: GridColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: GridColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
                ]))
              : _sinais.isEmpty
                  ? const Center(child: Text('Nenhum sinal disponível',
                        style: TextStyle(color: GridColors.divider, fontSize: 16)))
                  : RefreshIndicator(
                      color: GridColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sinais.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _SinalCard(sinal: _sinais[i]),
                      ),
                    ),
    );
  }
}

class _SinalCard extends StatelessWidget {
  final TradingSignal sinal;
  const _SinalCard({required this.sinal});

  Color get _corDirecao => sinal.direction.toUpperCase() == 'BUY'
      ? GridColors.secondary
      : GridColors.error;

  @override
  Widget build(BuildContext context) {
    final score = sinal.price > 0 ? sinal.price.toStringAsFixed(2) : '—';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _corDirecao.withAlpha(80), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _corDirecao.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  sinal.direction.toUpperCase() == 'BUY' ? '▲' : '▼',
                  style: TextStyle(fontSize: 24, color: _corDirecao),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(sinal.asset,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: GridColors.textSecondary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _corDirecao.withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _corDirecao.withAlpha(100)),
                      ),
                      child: Text(sinal.direction.toUpperCase(),
                          style: TextStyle(
                              color: _corDirecao,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('Entrada: R\$ $score',
                      style: const TextStyle(color: Colors.black87, fontSize: 13)),
                  if (sinal.createdAt.isNotEmpty)
                    Text(sinal.createdAt,
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
