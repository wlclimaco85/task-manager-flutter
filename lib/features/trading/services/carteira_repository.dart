import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../models/carteira_models.dart';

class CarteiraRepository {
  Future<CarteiraResumo> fetchCarteira() async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteira);
    final resp = await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode} em /api/trading/carteira');
    }
    return CarteiraResumo.fromJson(json.decode(resp.body));
  }

  Future<List<OperacaoAcao>> fetchOperacoes() async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteiraOperacoes);
    final resp = await http.get(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode} em /api/trading/carteira/operacoes');
    }
    final body = json.decode(resp.body);
    final list = body is List ? body : (body['data'] ?? []);
    return (list as List).map((e) => OperacaoAcao.fromJson(e)).toList();
  }

  Future<OperacaoAcao> adicionarOperacao(Map<String, dynamic> data) async {
    final url = TenantContext.applyToUrl('${ApiLinks.tradingCarteira}/operacao');
    final resp = await http.post(
      Uri.parse(url),
      headers: {...TenantContext.headers, 'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Erro ${resp.statusCode} ao adicionar operação');
    }
    return OperacaoAcao.fromJson(json.decode(resp.body));
  }

  Future<void> removerOperacao(int id) async {
    final url = TenantContext.applyToUrl(ApiLinks.tradingCarteiraOperacao(id.toString()));
    final resp = await http.delete(Uri.parse(url), headers: TenantContext.headers);
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw Exception('Erro ${resp.statusCode} ao remover operação');
    }
  }
}
