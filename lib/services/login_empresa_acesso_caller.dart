import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

/// Empresa com acesso APROVADO para o login logado — usado pelo picker
/// "Trocar Empresa" pos-login (Task 4, fase 178).
class EmpresaAcessoOption {
  final int empresaId;
  final String nome;
  final String status;

  EmpresaAcessoOption({
    required this.empresaId,
    required this.nome,
    required this.status,
  });

  factory EmpresaAcessoOption.fromJson(Map<String, dynamic> json) {
    return EmpresaAcessoOption(
      empresaId: json['empresaId'] as int? ?? json['id'] as int? ?? 0,
      nome: json['nome']?.toString() ??
          json['empresaNome']?.toString() ??
          json['razaoSocial']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'APROVADO',
    );
  }
}

/// Solicitacao de acesso a empresa pendente de aprovacao — usado pela tela
/// de aprovacao do gestor (Task 5, fase 178).
class LoginEmpresaAcessoPendenteItem {
  final int id;
  final String loginNome;
  final String loginEmail;
  final String empresaNome;
  final DateTime? dataCriacao;

  LoginEmpresaAcessoPendenteItem({
    required this.id,
    required this.loginNome,
    required this.loginEmail,
    required this.empresaNome,
    this.dataCriacao,
  });

  factory LoginEmpresaAcessoPendenteItem.fromJson(Map<String, dynamic> json) {
    return LoginEmpresaAcessoPendenteItem(
      id: json['id'] as int,
      loginNome: json['loginNome']?.toString() ?? json['nome']?.toString() ?? '',
      loginEmail:
          json['loginEmail']?.toString() ?? json['email']?.toString() ?? '',
      empresaNome:
          json['empresaNome']?.toString() ?? json['empresa']?.toString() ?? '',
      dataCriacao: DateTime.tryParse(json['dataCriacao']?.toString() ?? ''),
    );
  }
}

/// Resultado de uma acao (solicitar/aprovar/rejeitar/trocar). Molde exato de
/// `SolicitacaoAcessoActionResult` (services/solicitacao_acesso_caller.dart).
class LoginEmpresaAcessoActionResult {
  final bool sucesso;
  final String? mensagemErro;
  final bool conflito;

  const LoginEmpresaAcessoActionResult.ok()
      : sucesso = true,
        mensagemErro = null,
        conflito = false;

  const LoginEmpresaAcessoActionResult.erro(this.mensagemErro,
      {this.conflito = false})
      : sucesso = false;
}

class LoginEmpresaAcessoCaller {
  /// Injetavel apenas para teste (`package:http/testing.dart` MockClient).
  /// Em producao permanece o `http.Client()` default — nenhum outro
  /// arquivo referencia este campo, so os testes deste caller.
  @visibleForTesting
  static http.Client client = http.Client();

  static Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(TenantContext.headers);
    final token = AuthUtility.userInfo?.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Retorna lista vazia (nunca null) quando a requisicao falha ou o body
  /// vem malformado — o chamador (login_screen) so precisa saber "tem mais
  /// de 1 empresa aprovada?" e nao deve travar o fluxo de login por causa
  /// de um erro de rede/parsing nesta chamada auxiliar.
  static Future<List<EmpresaAcessoOption>> listarMinhasEmpresas() async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.minhasEmpresasAcesso);
      final response =
          await client.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final data = body is Map<String, dynamic> ? body['data'] : body;
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) =>
              EmpresaAcessoOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<LoginEmpresaAcessoActionResult> solicitar(
      int empresaId) async {
    try {
      final url = Uri.parse(
          TenantContext.applyToUrl(ApiLinks.loginEmpresaAcessoSolicitar));
      final response = await client.post(
        url,
        headers: {..._authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'empresaId': empresaId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const LoginEmpresaAcessoActionResult.ok();
      }
      if (response.statusCode == 409) {
        return LoginEmpresaAcessoActionResult.erro(
          _extrairMensagemErro(response.body) ??
              'Ja existe uma solicitacao para esta empresa.',
          conflito: true,
        );
      }
      return LoginEmpresaAcessoActionResult.erro(
        _extrairMensagemErro(response.body) ??
            'Erro ao solicitar acesso. Tente novamente.',
      );
    } catch (_) {
      return const LoginEmpresaAcessoActionResult.erro(
        'Erro de conexao ao solicitar acesso.',
      );
    }
  }

  /// Endpoint mais sensivel do fluxo (T-178-01 no threat model): so deve
  /// devolver sucesso quando ha uma aprovacao previa (ou MASTER) — a
  /// validacao real e feita no backend, aqui so parseamos o resultado.
  static Future<LoginEmpresaAcessoActionResult> trocarEmpresaAtiva(
      int empresaId) async {
    try {
      final url = Uri.parse(TenantContext.applyToUrl(ApiLinks.empresaAtiva));
      final response = await client.put(
        url,
        headers: {..._authHeaders, 'Content-Type': 'application/json'},
        body: jsonEncode({'empresaId': empresaId}),
      );
      if (response.statusCode == 200) {
        return const LoginEmpresaAcessoActionResult.ok();
      }
      if (response.statusCode == 403) {
        return LoginEmpresaAcessoActionResult.erro(
          _extrairMensagemErro(response.body) ??
              'Acesso a esta empresa nao foi aprovado.',
        );
      }
      return LoginEmpresaAcessoActionResult.erro(
        _extrairMensagemErro(response.body) ??
            'Erro ao trocar de empresa. Tente novamente.',
      );
    } catch (_) {
      return const LoginEmpresaAcessoActionResult.erro(
        'Erro de conexao ao trocar de empresa.',
      );
    }
  }

  /// Retorna null quando a requisicao falha (rede/parsing) — distinto de
  /// lista vazia (fila realmente sem pendencias). Molde de
  /// `SolicitacaoAcessoCaller.listarPendentes`.
  static Future<List<LoginEmpresaAcessoPendenteItem>?>
      listarPendentes() async {
    try {
      final url =
          TenantContext.applyToUrl(ApiLinks.loginEmpresaAcessoPendentes);
      final response =
          await client.get(Uri.parse(url), headers: _authHeaders);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! List) return null;
      return data
          .whereType<Map>()
          .map((e) => LoginEmpresaAcessoPendenteItem.fromJson(
              Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<LoginEmpresaAcessoActionResult> aprovar(int id) async {
    return _executarAcao(
      Uri.parse(
          TenantContext.applyToUrl(ApiLinks.loginEmpresaAcessoAprovar(id))),
      acaoLabel: 'aprovar',
    );
  }

  static Future<LoginEmpresaAcessoActionResult> rejeitar(int id) async {
    return _executarAcao(
      Uri.parse(
          TenantContext.applyToUrl(ApiLinks.loginEmpresaAcessoRejeitar(id))),
      acaoLabel: 'rejeitar',
    );
  }

  static Future<LoginEmpresaAcessoActionResult> _executarAcao(
    Uri url, {
    required String acaoLabel,
  }) async {
    try {
      final response = await client.post(url, headers: _authHeaders);
      if (response.statusCode == 200) {
        return const LoginEmpresaAcessoActionResult.ok();
      }
      // 404: outra pessoa ja decidiu a solicitacao antes (mesmo padrao de
      // SolicitacaoAcessoController).
      if (response.statusCode == 404) {
        return const LoginEmpresaAcessoActionResult.erro(
          'Esta solicitação já foi processada por outro usuário.',
          conflito: true,
        );
      }
      return LoginEmpresaAcessoActionResult.erro(
        _extrairMensagemErro(response.body) ??
            'Erro ao $acaoLabel solicitação. Tente novamente.',
      );
    } catch (_) {
      return LoginEmpresaAcessoActionResult.erro(
        'Erro de conexão ao $acaoLabel solicitação.',
      );
    }
  }

  static String? _extrairMensagemErro(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg =
          (json['response'] as Map<String, dynamic>?)?['message']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
      final msgDireto = json['message']?.toString();
      if (msgDireto != null && msgDireto.isNotEmpty) return msgDireto;
    } catch (_) {}
    return null;
  }
}
