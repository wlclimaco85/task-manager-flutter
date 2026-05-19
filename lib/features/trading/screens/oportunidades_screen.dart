import 'package:flutter/material.dart';
import '../trading_models.dart';
import '../trading_repository.dart';
import '../../../utils/grid_colors.dart';

class OportunidadesScreen extends StatefulWidget {
  const OportunidadesScreen({super.key});
  @override
  State<OportunidadesScreen> createState() => _OportunidadesScreenState();
}

class _OportunidadesScreenState extends State<OportunidadesScreen> {
  final _repo = TradingRepository();
  List<Opportunity> _oportunidades = [];
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
      final ops = await _repo.fetchOpportunities();
      // Ordena por score decrescente (ranking)
      // Ordena por descrição (score vem no campo description como "Score: XX")
      ops.sort((a, b) => a.asset.compareTo(b.asset));
      if (mounted) setState(() { _oportunidades = ops; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erro ao carregar oportunidades: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oportunidades — Ranking'),
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
              : _oportunidades.isEmpty
                  ? const Center(child: Text('Nenhuma oportunidade identificada',
                        style: TextStyle(color: GridColors.divider, fontSize: 16)))
                  : RefreshIndicator(
                      color: GridColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _oportunidades.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _OportunidadeCard(op: _oportunidades[i], rank: i + 1),
                      ),
                    ),
    );
  }
}

class _OportunidadeCard extends StatelessWidget {
  final Opportunity op;
  final int rank;
  const _OportunidadeCard({required this.op, required this.rank});

  Color _scoreCor(String desc) {
    // Tenta extrair número da description, ex: "Score: 87" ou "87%"
    final match = RegExp(r'\d+').firstMatch(desc);
    final score = match != null ? double.tryParse(match.group(0)!) ?? 50.0 : 50.0;
    if (score >= 80) return GridColors.secondary;
    if (score >= 50) return const Color(0xFFFFA000);
    return GridColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final cor = _scoreCor(op.description);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cor.withAlpha(80), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Posição no ranking
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? const Color(0xFFFFC107).withAlpha(40)
                    : Colors.grey.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('#$rank',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: rank <= 3 ? const Color(0xFFF57F17) : Colors.grey,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(op.asset,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: GridColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(op.description,
                      style: const TextStyle(color: Colors.black87, fontSize: 13)),
                ],
              ),
            ),
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cor.withAlpha(100)),
              ),
              child: Text(
                op.description,
                style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
