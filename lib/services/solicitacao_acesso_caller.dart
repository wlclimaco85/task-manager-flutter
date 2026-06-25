import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class SolicitacaoAcessoItem {
  final int id;
  final String nome;
  final String email;
  final String cpfCnpj;
  final String status;
  final int? parceiroIdResolvido;
  final DateTime? dataCriacao;

  SolicitacaoAcessoItem({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpfCnpj,
    required this.status,
    this.parceiroIdResolvido,
    this.dataCriacao,
  });

  bool get destinoFilaEscritorio => parceiroIdResolvido == null;

  factory SolicitacaoAcessoItem.fromJson(Map<String, dynamic> json) {
    return SolicitacaoAcessoItem(
      id: json['id'] as int,
      nome: json['nome']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cpfCnpj: json['cpfCnpj']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDENTE',
      parceiroIdResolvido: json['parceiroIdResolvido'] as int?,
      dataCriacao: DateTime.tryParse(json['dataCriacao']?.toString() ?? ''),
    );
  }
}

class SolicitacaoAcessoCaller {
  static Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(TenantContext.headers);
    final token = AuthUtility.userInfo?.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<SolicitacaoAcessoItem>> listarPendentes() async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoPendentes);
      final response = await http.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) =>
              SolicitacaoAcessoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Retorna null em sucesso, ou a mensagem de erro do backend em caso de falha.
  static Future<String?> aprovar(int id) async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoAprovar(id));
      final response = await http.post(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode == 200) return null;
      return _extrairMensagemErro(response.body);
    } catch (_) {
      return 'Erro de conexão ao aprovar solicitação.';
    }
  }

  /// Retorna null em sucesso, ou a mensagem de erro do backend em caso de falha.
  static Future<String?> rejeitar(int id) async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.solicitacaoAcessoRejeitar(id));
      final response = await http.post(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode == 200) return null;
      return _extrairMensagemErro(response.body);
    } catch (_) {
      return 'Erro de conexão ao rejeitar solicitação.';
    }
  }

  static String _extrairMensagemErro(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg =
          (json['response'] as Map<String, dynamic>?)?['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'Esta solicitação já foi processada por outro usuário.';
  }
}
