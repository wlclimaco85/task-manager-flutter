import 'package:flutter/material.dart';
import '../models/trading_models.dart';
import '../services/trading_repository.dart';

class TradingDashboardScreen extends StatefulWidget {
  final TradingRepository repository;
  const TradingDashboardScreen({super.key, required this.repository});

  @override
  State<TradingDashboardScreen> createState() => _TradingDashboardScreenState();
}

class _TradingDashboardScreenState extends State<TradingDashboardScreen> {
  List<TradingSignal> signals = [];
  List<Opportunity> opportunities = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      signals = await widget.repository.fetchSignals();
      opportunities = await widget.repository.fetchOpportunities();
    } catch (e) {
      setState(() { error = 'Erro ao carregar dados: $e'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Top Signals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...signals.map((s) => ListTile(
          title: Text('${s.assetSymbol} — ${s.signalType}'),
          subtitle: Text('Score: ${s.score}'),
        )),
        const SizedBox(height: 12),
        const Text('Opportunities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...opportunities.map((o) => ListTile(
          title: Text('${o.assetSymbol} — ${o.recommendation}'),
          subtitle: Text('Score: ${o.scoreValue}'),
        )),
      ],
    );
  }
}
