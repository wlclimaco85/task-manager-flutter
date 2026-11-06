import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Envia, consulta e remove a logo do DANFSe (PNG/JPEG) da empresa ou do parceiro.
class NfseLogoService {
  /// Envia a logo. Retorna null quando o backend aceitou, ou a mensagem de erro do backend.
  static Future<String?> enviarEmpresa(int empresaId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoEmpresa(empresaId.toString()), bytes, nomeArquivo);

  static Future<String?> enviarParceiro(int parceiroId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoParceiro(parceiroId.toString()), bytes, nomeArquivo);

  /// Bytes da logo cadastrada. Null quando nao ha logo (404) ou quando a consulta falhou (logado).
  static Future<List<int>?> buscar(String url) async {
    try {
      final resposta = await TenantContext.get(url);
      if (resposta.statusCode == 200) return resposta.bodyBytes;
      if (resposta.statusCode != 404) {
        AppLogger.i.warn('[NFSE-LOGO] consulta da logo recusada (HTTP ${resposta.statusCode})');
      }
      return null;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao buscar logo: $e', st);
      return null;
    }
  }

  /// Remove a logo cadastrada. Retorna true quando o backend confirmou (204).
  static Future<bool> remover(String url) async {
    try {
      final resposta = await TenantContext.delete(url);
      return resposta.statusCode == 204;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao remover logo: $e', st);
      return false;
    }
  }

  static Future<String?> _enviar(String url, List<int> bytes, String nomeArquivo) async {
    try {
      final resposta = await TenantContext.postMultipart(
        url,
        fileBytes: bytes,
        fileName: nomeArquivo,
        fileField: 'arquivo',
      );
      if (resposta.statusCode == 200) return null;
      AppLogger.i.warn('[NFSE-LOGO] envio recusado (HTTP ${resposta.statusCode})');
      return _mensagemDoBackend(resposta.body) ??
          'Nao foi possivel salvar a logo (HTTP ${resposta.statusCode}).';
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao enviar logo: $e', st);
      return 'Falha de conexao ao enviar a logo.';
    }
  }

  /// Extrai a mensagem do corpo de erro do backend (campo "message"/"mensagem"/"error"), se houver.
  static String? _mensagemDoBackend(String corpo) {
    try {
      final json = jsonDecode(corpo);
      if (json is Map) {
        final msg = json['message'] ?? json['mensagem'] ?? json['error'];
        if (msg is String && msg.trim().isNotEmpty) return msg;
      }
    } catch (_) {
      // corpo nao e JSON: sem mensagem especifica
    }
    return null;
  }
}
