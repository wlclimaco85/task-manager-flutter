import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/nfse_ux_helper.dart';
import '../utils/tenant_context.dart';

class NfseCaller {
  Future<Map<String, dynamic>> emitir({
    required String municipio,
    required String cnpjTomador,
    required String nomeTomador,
    required String descricaoServico,
    required double valor,
    required double aliquotaIss,
    required String cnae,
    required String codigoTributacao,
    // Card 4phuZyDS: empresaId é @NotNull em NfseEmitirRequest (backend) e
    // não é preenchido automaticamente por TenantContext.applyToBody (que só
    // injeta 'empresa': {'id': ...} aninhado, não o campo flat 'empresaId'
    // que o record espera) -- por isso precisa ser passado explicitamente
    // por quem já conhece a empresa ativa (ex: nfse_detail_screen.dart).
    String? empresaId,
    // Card 4phuZyDS: id do registro Nfse (persistence.entity.Nfse) real
    // sendo emitido. Quando presente, o backend persiste o status retornado
    // pela prefeitura de volta no registro (NfseFacade.sincronizarStatusNoRegistro),
    // fechando o ciclo com a tela de detalhe real (nfse_detail_screen.dart).
    // Null preserva o comportamento anterior do painel avulso de diagnostico.
    int? nfseId,
  }) async {
    final url = ApiLinks.nfseEmitir;
    final body = {
      'municipio': municipio,
      'cnpjTomador': cnpjTomador,
      'nomeTomador': nomeTomador,
      'descricaoServico': descricaoServico,
      'valor': valor,
      'aliquotaIss': aliquotaIss,
      'cnae': cnae,
      'codigoTributacao': codigoTributacao,
      if (empresaId != null) 'empresaId': int.tryParse(empresaId) ?? empresaId,
      if (nfseId != null) 'nfseId': nfseId,
    };
    final response = await TenantContext.post(url, body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'Falha ao emitir NFSe'),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> consultar(String numero) async {
    final url = ApiLinks.nfseStatusNumero(numero);
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'NFSe não encontrada'),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> cancelar({
    required String numero,
    required String motivo,
    // Card 4phuZyDS: mesma necessidade de empresaId explícito do emitir()
    // (NfseCancelarRequest.empresaId é @NotNull e TenantContext não injeta
    // o campo flat).
    String? empresaId,
    // Card 4phuZyDS: municipio é @NotBlank em NfseCancelarRequest -- sem ele
    // o backend sempre rejeitava com 400, mesmo antes desta mudança.
    String? municipio,
    // Card 4phuZyDS: mesma semântica de NfseEmitirRequest.nfseId.
    int? nfseId,
  }) async {
    final url = ApiLinks.nfseCancelar;
    final body = {
      // BUG pré-existente: o backend (NfseCancelarRequest.nfseNumber,
      // @NotBlank) sempre esperou a chave 'nfseNumber', nunca 'numero' --
      // toda chamada de cancelamento retornava 400 antes desta correção.
      'nfseNumber': numero,
      'motivo': motivo,
      if (empresaId != null) 'empresaId': int.tryParse(empresaId) ?? empresaId,
      if (municipio != null) 'municipio': municipio,
      if (nfseId != null) 'nfseId': nfseId,
    };
    final response = await TenantContext.post(url, body);
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return {'status': 'cancelado'};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'Falha ao cancelar NFSe'),
      statusCode: response.statusCode,
    );
  }

  Future<List<Map<String, dynamic>>> auditoria() async {
    final url = ApiLinks.nfseAuditoria;
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.cast<Map<String, dynamic>>();
      }
      if (body is Map && body['content'] is List) {
        return (body['content'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw NfseException(
      _extractError(response, 'Falha ao buscar auditoria'),
      statusCode: response.statusCode,
    );
  }

  String _extractError(http.Response response, String fallback) {
    return NfseUxHelper.readableHttpError(
      response.statusCode,
      response.body,
      fallback,
    );
  }
}

class NfseException implements Exception {
  final String message;
  final int statusCode;
  const NfseException(this.message, {this.statusCode = -1});
  @override
  String toString() => 'NfseException($statusCode): $message';
}
