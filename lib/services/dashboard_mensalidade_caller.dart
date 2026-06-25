import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class DashboardMensalidadeCaller {
  static final String _base = '${ApiLinks.baseUrl}/api/dashboard/mensalidade';

  Future<Map<String, dynamic>?> fetchKpis({String? mesInicio, String? mesFim}) async {
    try {
      final params = <String>[];
      if (mesInicio != null) params.add('mesInicio=$mesInicio');
      if (mesFim != null) params.add('mesFim=$mesFim');
      final url = '$_base/kpis${params.isNotEmpty ? '?${params.join('&')}' : ''}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] fetchKpis: $e');
    }
    return null;
  }

  Future<Uint8List?> baixarPdf({String? mesInicio, String? mesFim}) async {
    try {
      final params = <String>[];
      if (mesInicio != null) params.add('mesInicio=$mesInicio');
      if (mesFim != null) params.add('mesFim=$mesFim');
      final url = '$_base/relatorio-pdf${params.isNotEmpty ? '?${params.join('&')}' : ''}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) return resp.bodyBytes;
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] baixarPdf: $e');
    }
    return null;
  }
}
