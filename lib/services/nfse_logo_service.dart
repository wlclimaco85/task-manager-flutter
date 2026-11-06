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
