import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NfeSaidaService {

  Future<List<Map<String, dynamic>>> carregarTiposOperacao() async {
    try {
      final r = await TenantContext.get('${ApiLinks.allNfeTipoOperacao}?tamanho=200&ativo=true');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        return (data as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> criarNfe(Map<String, dynamic> body) async {
    try {
      final r = await TenantContext.post(ApiLinks.createNfe, body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        if (b is Map) {
          final data = b['data'] is Map ? b['data'] : b;
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> buscarNfe(String id) async {
    try {
      final r = await TenantContext.get(ApiLinks.nfeById(id));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] is Map ? b['data'] : b) : null;
        return data != null ? Map<String, dynamic>.from(data) : null;
      }
    } catch (_) {}
    return null;
  }
}
