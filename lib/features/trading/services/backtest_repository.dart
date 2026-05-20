import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/backtest_models.dart';

class BacktestRepository {
  final String baseUrl;
  final Map<String, String> headers;

  BacktestRepository(this.baseUrl, {this.headers = const {}});

  Future<BacktestRunResponse> runBacktest({
    required String assetSymbol,
    required String strategyName,
    String? ruleParams,
    String? periodStart,
    String? periodEnd,
  }) async {
    final body = {
      'assetSymbol': assetSymbol,
      'strategyName': strategyName,
      if (ruleParams != null) 'ruleParams': ruleParams,
      if (periodStart != null) 'periodStart': periodStart,
      if (periodEnd != null) 'periodEnd': periodEnd,
    };
    final uri = Uri.parse('$baseUrl/api/trading/backtest/run');
    final resp = await http.post(uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(body));
    if (resp.statusCode != 200) throw Exception('Erro HTTP ${resp.statusCode} em /api/trading/backtest/run');
    return BacktestRunResponse.fromJson(json.decode(resp.body));
  }

  Future<List<BacktestRunResponse>> listRuns() async {
    final uri = Uri.parse('$baseUrl/api/trading/backtest/runs');
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) throw Exception('Erro HTTP ${resp.statusCode} em /api/trading/backtest/runs');
    final list = json.decode(resp.body) as List;
    return list.map((e) => BacktestRunResponse.fromJson(e)).toList();
  }
}
