import 'tenant_context.dart';

class TenantHelper {
  static bool get isAdmin => TenantContext.isAdmin;
  static String? get empresaId => TenantContext.empresaId?.toString();
  static String? get parceiroId => TenantContext.parceiroId?.toString();
  
  static Map<String, String> get tenantHeaders {
    final headers = <String, String>{};
    if (!isAdmin && empresaId != null) {
      headers['X-Empresa-Id'] = empresaId!;
    }
    if (parceiroId != null) {
      headers['X-Parceiro-Id'] = parceiroId!;
    }
    return headers;
  }
  
  static String? applyToUrl(String? url) => url;
  static Map<String, dynamic> applyToBody(Map<String, dynamic> body) {
    if (!isAdmin && empresaId != null) {
      body['empresaId'] = int.tryParse(empresaId!);
    }
    if (parceiroId != null) {
      body['parceiroId'] = int.tryParse(parceiroId!);
    }
    return body;
  }
  
  static String get debugInfo => 'empId=$empresaId, parcId=$parceiroId, admin=$isAdmin';
}
