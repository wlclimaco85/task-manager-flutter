import 'dart:convert';
import '../models/auth_utility.dart';
import 'package:http/http.dart' as http;

/// Contexto de tenant do usuário logado.
/// Injeta empresa, parceiro e userId em TODAS as chamadas HTTP.
class TenantContext {
  TenantContext._();

  // ── Leitura dos dados do usuário logado ──────────────────────────────────
  // Tenta login direto primeiro, depois data.login como fallback
  static int? get empresaId =>
      AuthUtility.userInfo?.login?.empresa?.id ??
      AuthUtility.userInfo?.data?.login?.empresa?.id;

  static int? get parceiroId =>
      AuthUtility.userInfo?.login?.parceiro?.id ??
      AuthUtility.userInfo?.data?.login?.parceiro?.id;

  static int? get aplicativoId =>
      AuthUtility.userInfo?.login?.aplicativo?.id ??
      AuthUtility.userInfo?.data?.login?.aplicativo?.id;

  static int? get userId =>
      AuthUtility.userInfo?.login?.id ??
      AuthUtility.userInfo?.data?.login?.id ??
      AuthUtility.userInfo?.data?.id;

  static bool get hasEmpresa => empresaId != null;
  static bool get hasParceiro => parceiroId != null;
  static bool get hasUser => userId != null;

  // ── Headers ──────────────────────────────────────────────────────────────
  static Map<String, String> get headers {
    final token = AuthUtility.userInfo?.token;
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept-Encoding': 'gzip',
    };
  }

  static Map<String, String> get jsonHeaders {
    final token = AuthUtility.userInfo?.token;
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── Injeção de tenant na URL ─────────────────────────────────────────────
  /// Injeta empresa, parceiro e userId em TODOS os nomes que os controllers aceitam.
  /// Se não tem nenhum (admin puro) → não filtra.
  static String applyToUrl(String url) {
    final uri = Uri.parse(url);
    final params = Map<String, String>.from(uri.queryParameters);

    // Empresa — usa apenas empId
    if (hasEmpresa) {
      params['empId'] = empresaId.toString();
    }
    // Sem empresa → não injeta filtro (admin sem empresa vê tudo)

    // Parceiro/Cliente — todos os nomes que os controllers aceitam
    if (hasParceiro) {
      params['parceiro']   = parceiroId.toString();
      params['parceiroId'] = parceiroId.toString();
      params['parcId']     = parceiroId.toString();
      params['clienteId']  = parceiroId.toString();
    }

    // UserId — para controllers que filtram por usuário logado
    if (hasUser) {
      params['userId']         = userId.toString();
      params['userLogadoId']   = userId.toString();
    }

    return uri.replace(queryParameters: params).toString();
  }

  // ── Injeção no body ──────────────────────────────────────────────────────
  static Map<String, dynamic> applyToBody(Map<String, dynamic> body) {
    final result = Map<String, dynamic>.from(body);
    if (hasEmpresa && result['empresa'] == null) {
      result['empresa'] = {'id': empresaId};
    }
    if (hasParceiro && result['parceiro'] == null) {
      result['parceiro'] = {'id': parceiroId};
    }
    if (aplicativoId != null && result['aplicativo'] == null) {
      result['aplicativo'] = {'id': aplicativoId};
    }
    return result;
  }

  // ── Helpers HTTP com tenant automático ──────────────────────────────────
  static Future<http.Response> get(String url) {
    return http.get(Uri.parse(applyToUrl(url)), headers: headers);
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) {
    return http.put(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
      body: jsonEncode(applyToBody(body)),
    );
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) {
    return http.post(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
      body: jsonEncode(applyToBody(body)),
    );
  }

  static Future<http.Response> delete(String url) {
    return http.delete(
      Uri.parse(applyToUrl(url)),
      headers: jsonHeaders,
    );
  }

  /// Envia um arquivo via multipart/form-data com headers de autenticação.
  static Future<http.Response> postMultipart(
    String url, {
    required List<int> fileBytes,
    required String fileName,
    required String fileField,
    Map<String, String>? fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(applyToUrl(url)));
    final token = AuthUtility.userInfo?.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    // Força charset UTF-8 para que o Spring interprete os campos corretamente
    request.headers['Accept-Charset'] = 'utf-8';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(http.MultipartFile.fromBytes(
      fileField,
      fileBytes,
      filename: fileName,
    ));
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ── Debug ────────────────────────────────────────────────────────────────
  static String get debugInfo =>
      'empresaId=$empresaId | parceiroId=$parceiroId | userId=$userId';
}
