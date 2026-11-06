import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Envia a logo do DANFSe (PNG/JPEG) da empresa ou do parceiro cadastrado.
class NfseLogoService {
  /// Retorna true quando o backend aceitou a logo.
  static Future<bool> enviarEmpresa(int empresaId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoEmpresa(empresaId.toString()), bytes, nomeArquivo);

  static Future<bool> enviarParceiro(int parceiroId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoParceiro(parceiroId.toString()), bytes, nomeArquivo);

  /// Bytes da logo cadastrada, ou null quando nao ha logo (404) ou a consulta falhou.
  static Future<List<int>?> buscar(String url) async {
    try {
      final resposta = await TenantContext.get(url);
      return resposta.statusCode == 200 ? resposta.bodyBytes : null;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao buscar logo: $e', st);
      return null;
    }
  }

  /// Remove a logo cadastrada. Retorna true quando o backend confirmou (204).
  static Future<bool> remover(String url) async {
    try {
      final resposta = await http.delete(
        Uri.parse(TenantContext.applyToUrl(url)),
        headers: TenantContext.headers,
      );
      return resposta.statusCode == 204;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao remover logo: $e', st);
      return false;
    }
  }

  static Future<bool> _enviar(String url, List<int> bytes, String nomeArquivo) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(TenantContext.applyToUrl(url)));
      request.headers.addAll(TenantContext.headers);
      request.files.add(http.MultipartFile.fromBytes('arquivo', bytes, filename: nomeArquivo));
      final resposta = await request.send();
      if (resposta.statusCode != 200) {
        AppLogger.i.warn('[NFSE-LOGO] envio recusado (HTTP ${resposta.statusCode})');
        return false;
      }
      return true;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao enviar logo: $e', st);
      return false;
    }
  }
}
