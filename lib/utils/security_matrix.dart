// lib/utils/security_matrix.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/login_model.dart';
import '../utils/api_links.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Telas / recursos
// ─────────────────────────────────────────────────────────────────────────────
enum AppScreen {
  // Mobile – Bottom Nav
  calendario, chat, comunicados, chamados, ged,
  // Mobile – Menu Mais
  contasPagar, contasReceber, parceiros, dashboard, contasBancarias,
  ponto, funcionarios,
  // Dashboard widgets
  dashKpis, dashFinanceCards, dashFluxoDiario, dashTendenciaFinanceira,
  dashDistribuicaoClientes, dashComparativoTrimestral, dashAlertas,
  dashChamadosCards, dashChamadosPie, dashTendenciaChamados,
  dashChatsLinha, dashChatsDiario, dashSaldoContas, dashEvolucaoSaldos,
  // Web / Windows – Sidebar
  noticias, logins, cotacao, trading, comprar, aplicativo, vender, perfil,
  regimeTributario, alimentos, dietas, empresas, exames, exercicios,
  gruposMusculares, medicamentos, mensalidades, modalidades, objetivos,
  personais, planos, roles, setores, suplementos,
  formasPagamento, diretorios, arquivos, obrigacoesFiscais,
  // Novas telas
  pedidos, configuracoesAdmin, contaBancaria, feriados,
  kanbanChamados, nfeEntrada, nfeSaida,
  // Ponto web
  pontoWeb, solicitacaoAjustePonto, ajustePonto,
  // Admin sistema — só ROLE_SYSTEM
  configSistema,
  // Novas telas cadastro
  tipoParceiro, servicoContratado, moduloServico,
  // Produto
  produto,
  // Cadastros auxiliares NF-e e produto
  unidadeMedida, catalogoProduto, nfeSerie, pdvNfce, configFiscal,
  // NFS-e (Notas Fiscais de Servico — modulo separado de Notas Fiscais NF-e)
  nfse,
  nfseLista, nfseSerie, nfseServico,
  // Dashboards por área (Fase 171 — fundação)
  dashAtendimentoArea, dashFinanceiroArea, dashComercialArea,
  dashDpArea, dashFiscalArea,
  // Dashboard de mensalidades do escritorio
  dashMensalidadeArea,
  // Importação de boletos em lote
  boletoImportacaoLote,
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Ações
// ─────────────────────────────────────────────────────────────────────────────
enum AppAction { view, insert, update, delete, baixar }

// ─────────────────────────────────────────────────────────────────────────────
// 3. Perfis (mantidos para compatibilidade com código legado)
// ─────────────────────────────────────────────────────────────────────────────
enum UserProfile {
  system, escritorio, gerente, financeiro, faturista, ponto, semAcesso,
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Mapeamento role.key → UserProfile
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, UserProfile> _roleKeyToProfile = {
  'ROLE_SYSTEM':     UserProfile.system,
  'ROLE_ESCRITORIO': UserProfile.escritorio,
  'ROLE_GERENTE':    UserProfile.gerente,
  'ROLE_FINANCEIRO': UserProfile.financeiro,
  'ROLE_FATURISTA':  UserProfile.faturista,
  'ROLE_PONTO':      UserProfile.ponto,
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. Atalhos
// ─────────────────────────────────────────────────────────────────────────────
const _all         = {AppAction.view, AppAction.insert, AppAction.update, AppAction.delete};
const _allFinanceiro = {AppAction.view, AppAction.insert, AppAction.update, AppAction.delete, AppAction.baixar};
const _ro          = {AppAction.view};

// Telas do ESCRITORIO (fallback hardcoded)
const _escritorioScreens = {
  AppScreen.logins:             _all,
  AppScreen.comunicados:        _all,
  AppScreen.regimeTributario:   _all,
  AppScreen.empresas:           _all,
  AppScreen.parceiros:          _all,
  AppScreen.setores:            _all,
  AppScreen.produto:            _all,
  AppScreen.unidadeMedida:      _all,
  AppScreen.catalogoProduto:    _all,
  AppScreen.nfeSerie:           _all,
  AppScreen.contasPagar:        _allFinanceiro,
  AppScreen.contasReceber:      _allFinanceiro,
  AppScreen.trading:            _ro,
  AppScreen.chamados:           _all,
  AppScreen.formasPagamento:    _all,
  AppScreen.diretorios:         _all,
  AppScreen.arquivos:           _all,
  AppScreen.calendario:         _all,
  AppScreen.obrigacoesFiscais:  _all,
  AppScreen.pedidos:            _all,
  AppScreen.configuracoesAdmin: _all,
  AppScreen.contasBancarias:    _all,
  AppScreen.contaBancaria:      _all,
  AppScreen.dashboard:          _ro,
  AppScreen.feriados:           _all,
  AppScreen.funcionarios:       _all,
  AppScreen.kanbanChamados:     _all,
  AppScreen.nfeEntrada:         _all,
  AppScreen.nfeSaida:           _all,
  AppScreen.nfse:               _all,
  AppScreen.pdvNfce:            _all,
  AppScreen.configFiscal:       _all,
  AppScreen.dashKpis:                  _ro,
  AppScreen.dashFinanceCards:          _ro,
  AppScreen.dashFluxoDiario:           _ro,
  AppScreen.dashTendenciaFinanceira:   _ro,
  AppScreen.dashDistribuicaoClientes:  _ro,
  AppScreen.dashComparativoTrimestral: _ro,
  AppScreen.dashAlertas:               _ro,
  AppScreen.dashChamadosCards:         _ro,
  AppScreen.dashChamadosPie:           _ro,
  AppScreen.dashTendenciaChamados:     _ro,
  AppScreen.dashChatsLinha:            _ro,
  AppScreen.dashChatsDiario:           _ro,
  AppScreen.dashSaldoContas:           _ro,
  AppScreen.dashEvolucaoSaldos:        _ro,
  AppScreen.dashAtendimentoArea:       _ro,
  AppScreen.dashFinanceiroArea:        _ro,
  AppScreen.dashComercialArea:         _ro,
  AppScreen.dashDpArea:                _ro,
  AppScreen.dashFiscalArea:            _ro,
  AppScreen.dashMensalidadeArea:       _ro,
  AppScreen.ponto:                     _all,
  AppScreen.pontoWeb:                  _all,
  AppScreen.solicitacaoAjustePonto:    _all,
  AppScreen.ajustePonto:               _all,
  AppScreen.ged:        _all,
  AppScreen.chat:       _all,
  AppScreen.perfil:     _all,
  AppScreen.boletoImportacaoLote: _allFinanceiro,
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. Matriz fallback (hardcoded — usada quando backend não retorna permissões)
// ─────────────────────────────────────────────────────────────────────────────
final Map<UserProfile, Map<AppScreen, Set<AppAction>>> _fallbackMatrix = {
  UserProfile.system: { for (final s in AppScreen.values) s: _all },
  UserProfile.escritorio: _escritorioScreens,
  UserProfile.gerente: { ..._escritorioScreens, AppScreen.regimeTributario: const {} },
  UserProfile.financeiro: {
    AppScreen.parceiros:       _all,
    AppScreen.formasPagamento: _all,
    AppScreen.trading:         _ro,
    AppScreen.diretorios:      _all,
    AppScreen.arquivos:        _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria:   _all,
    AppScreen.contasPagar:     _allFinanceiro,
    AppScreen.contasReceber:   _allFinanceiro,
    AppScreen.nfeEntrada:      _all,
    AppScreen.nfeSaida:        _all,
    AppScreen.nfse:            _all,
    AppScreen.pdvNfce:         _all,
    AppScreen.configFiscal:    _all,
    AppScreen.dashboard:       _ro,
    AppScreen.dashKpis:                  _ro,
    AppScreen.dashFinanceCards:          _ro,
    AppScreen.dashFluxoDiario:           _ro,
    AppScreen.dashTendenciaFinanceira:   _ro,
    AppScreen.dashDistribuicaoClientes:  _ro,
    AppScreen.dashComparativoTrimestral: _ro,
    AppScreen.dashAlertas:               _ro,
    AppScreen.dashSaldoContas:           _ro,
    AppScreen.dashEvolucaoSaldos:        _ro,
    AppScreen.noticias:  _ro,
    AppScreen.perfil:    _all,
    AppScreen.calendario: _ro,
    AppScreen.ponto:     {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:  {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
  },
  UserProfile.faturista: {
    AppScreen.empresas:        _ro,
    AppScreen.parceiros:       _all,
    AppScreen.produto:         _all,
    AppScreen.unidadeMedida:   _all,
    AppScreen.catalogoProduto: _all,
    AppScreen.nfeSerie:        _all,
    AppScreen.formasPagamento: _all,
    AppScreen.diretorios:      _all,
    AppScreen.arquivos:        _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria:   _all,
    AppScreen.contasPagar:     _allFinanceiro,
    AppScreen.contasReceber:   _allFinanceiro,
    AppScreen.nfeEntrada:      _all,
    AppScreen.nfeSaida:        _all,
    AppScreen.nfse:            _all,
    AppScreen.pdvNfce:         _all,
    AppScreen.configFiscal:    _all,
    AppScreen.noticias:        _ro,
    AppScreen.perfil:          _all,
    AppScreen.calendario:      _ro,
    AppScreen.ponto:           {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:        {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat:            _ro,
    AppScreen.comunicados:     _ro,
    AppScreen.chamados:        _all,
    AppScreen.ged:             _all,
  },
  UserProfile.ponto: {
    AppScreen.calendario:             _ro,
    AppScreen.ponto:                  {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:               {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat:                   _ro,
    AppScreen.comunicados:            _ro,
    AppScreen.noticias:               _ro,
    AppScreen.perfil:                 _ro,
  },
  UserProfile.semAcesso: {},
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. Classe principal
// ─────────────────────────────────────────────────────────────────────────────
class SecurityMatrix {
  final UserProfile profile;
  final LoginEnum? tipoLogin;
  final String? aplicativoNome;

  /// Permissões vindas do banco (quando disponíveis)
  final Map<String, Set<AppAction>> _backendPerms;

  /// Cache de permissões por módulo+ação para avoid recalcular
  final Map<String, bool> _moduloAcaoCache;

  const SecurityMatrix._({
    required this.profile,
    this.tipoLogin,
    this.aplicativoNome,
    Map<String, Set<AppAction>> backendPerms = const {},
    Map<String, bool> moduloAcaoCache = const {},
  }) : _backendPerms = backendPerms, _moduloAcaoCache = moduloAcaoCache;

  factory SecurityMatrix.of(LoginModel? userInfo) {
    if (userInfo == null) return const SecurityMatrix._(profile: UserProfile.semAcesso);

    final login = userInfo.login;
    final tipoLogin = login?.tipoLogin;
    final aplicativoNome = login?.aplicativo?.nome;

    // MASTER sempre tem acesso total
    if (tipoLogin == LoginEnum.MASTER) {
      return SecurityMatrix._(
        profile: UserProfile.system,
        tipoLogin: tipoLogin,
        aplicativoNome: aplicativoNome,
        backendPerms: {},
      );
    }

    // Resolve perfil para fallback
    final roles = login?.roles ?? [];
    UserProfile resolved = UserProfile.semAcesso;
    const priority = [
      UserProfile.system, UserProfile.escritorio, UserProfile.gerente,
      UserProfile.financeiro, UserProfile.faturista, UserProfile.ponto,
    ];
    for (final p in priority) {
      final key = _roleKeyToProfile.entries
          .firstWhere((e) => e.value == p, orElse: () => const MapEntry('', UserProfile.semAcesso))
          .key;
      if (roles.any((r) => r.key == key)) { resolved = p; break; }
    }
    if (resolved == UserProfile.semAcesso && roles.isNotEmpty) resolved = UserProfile.escritorio;
    if (resolved == UserProfile.semAcesso && tipoLogin != null) resolved = UserProfile.escritorio;

    // Constrói mapa de permissões do backend (consolidado por tela — OR entre roles)
    final backendPerms = <String, Set<AppAction>>{};
    if (userInfo.permissoes != null && userInfo.permissoes!.isNotEmpty) {
      for (final p in userInfo.permissoes!) {
        final existing = backendPerms[p.telaNome] ?? <AppAction>{};
        if (p.podeVer)      existing.add(AppAction.view);
        if (p.podeInserir)  existing.add(AppAction.insert);
        if (p.podeEditar)   existing.add(AppAction.update);
        if (p.podeDeletar)  existing.add(AppAction.delete);
        if (p.podeBaixar)   existing.add(AppAction.baixar);
        backendPerms[p.telaNome] = existing;
      }
    }

    return SecurityMatrix._(
      profile: resolved,
      tipoLogin: tipoLogin,
      aplicativoNome: aplicativoNome,
      backendPerms: backendPerms,
    );
  }

  factory SecurityMatrix.current() => SecurityMatrix.of(AuthUtility.userInfo);

  bool _can(AppScreen screen, AppAction action) {
    // MASTER/SYSTEM: acesso total
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return ModuloAccess.isScreenAllowed(screen);
    }

    // Regra Financeiro Limitado: cliente sem módulo Financeiro completo só pode
    // VER e BAIXAR em Contas a Pagar; Contas a Receber fica bloqueada.
    if (screen == AppScreen.contasPagar &&
        !ModuloAccess.isModuloContratado('Financeiro') &&
        ModuloAccess.isModuloContratado('Financeiro Limitado')) {
      return action == AppAction.view || action == AppAction.baixar;
    }

    // Se backend retornou permissões, usa elas
    if (_backendPerms.isNotEmpty) {
      final perms = _backendPerms[screen.name];
      if (perms == null) return false;
      return perms.contains(action) && ModuloAccess.isScreenAllowed(screen);
    }

    // Fallback: matrix hardcoded
    final hasRole = _fallbackMatrix[profile]?[screen]?.contains(action) ?? false;
    if (!hasRole) return false;
    return ModuloAccess.isScreenAllowed(screen);
  }

  bool canView(AppScreen screen)   => _can(screen, AppAction.view);
  bool canInsert(AppScreen screen) => _can(screen, AppAction.insert);
  bool canUpdate(AppScreen screen) => _can(screen, AppAction.update);
  bool canDelete(AppScreen screen) => _can(screen, AppAction.delete);
  bool canBaixar(AppScreen screen) => _can(screen, AppAction.baixar);

  // ───────────────────────────────────────────────────────────────────────────
  // Enforcement por telaNome canônico (= MenuConfig.id). Independe do enum
  // AppScreen (que cobre só parte das telas). Usado pelo filtro do menu lateral.
  // ───────────────────────────────────────────────────────────────────────────

  /// MASTER/SYSTEM têm acesso total e ignoram o filtro de permissões.
  bool get isMaster =>
      profile == UserProfile.system || tipoLogin == LoginEnum.MASTER;

  /// IDs de tela (telaNome) que o usuário pode VISUALIZAR, vindas do backend,
  /// filtradas também por acesso de módulo contratado.
  Set<String> get viewableTelaIds {
    final result = <String>{};
    _backendPerms.forEach((tela, actions) {
      if (!actions.contains(AppAction.view)) return;
      // Filtra telas de módulos não contratados
      final screen = AppScreen.values.where((s) => s.name == tela).firstOrNull;
      if (screen != null && !ModuloAccess.isScreenAllowed(screen)) return;
      result.add(tela);
    });
    return result;
  }

  /// Calcula quais [allKnownIds] (ids do menu) o usuário pode ver.
  /// Retorna `null` quando NÃO deve filtrar (mostrar tudo) — casos anti-lockout:
  ///  - usuário MASTER/SYSTEM;
  ///  - role sem nenhuma permissão de view aplicável ao menu (não configurada
  ///    ou apenas com dados legados que não casam com nenhum id do menu).
  /// Caso contrário retorna o conjunto de ids liberados.
  Set<String>? allowedTelaIds(Set<String> allKnownIds) {
    if (isMaster) return null;
    final viewable = viewableTelaIds.intersection(allKnownIds);
    if (viewable.isEmpty) return null; // anti-lockout
    return viewable;
  }

  bool hasRoleKey(String roleKey) {
    final roles = AuthUtility.userInfo?.login?.roles ?? const [];
    return roles.any((role) => role.key == roleKey);
  }

  bool get canManageFiscalEvents {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) return true;
    return hasRoleKey('ROLE_ADMIN') || hasRoleKey('ROLE_FISCAL');
  }

  bool get isFinanceiroLimitado =>
      !ModuloAccess.isModuloContratado('Financeiro') &&
      ModuloAccess.isModuloContratado('Financeiro Limitado');

  bool hasAnyAccess(AppScreen screen) {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) return true;
    if (_backendPerms.isNotEmpty) return (_backendPerms[screen.name]?.isNotEmpty) ?? false;
    return (_fallbackMatrix[profile]?[screen]?.isNotEmpty) ?? false;
  }

  /// Verifica se o usuário tem uma ação específica em um módulo.
  /// Retorna false se o módulo não existe ou se não há a ação.
  /// Usa cache para evitar recálculos repetidos.
  bool canActionInModulo(AppAction acao, String nomeModulo) {
    // MASTER/SYSTEM: acesso total
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return true;
    }

    // Valida se o módulo existe
    if (!_moduloToScreens.containsKey(nomeModulo)) {
      return false;
    }

    // Chave de cache: "nomeModulo:acao"
    final cacheKey = '$nomeModulo:${acao.name}';
    if (_moduloAcaoCache.containsKey(cacheKey)) {
      return _moduloAcaoCache[cacheKey] ?? false;
    }

    // Calcula: há permissão para a ação em ALGUMA tela do módulo?
    final telasDModulo = _moduloToScreens[nomeModulo] ?? {};
    bool temAcao = false;

    for (final tela in telasDModulo) {
      if (_can(tela, acao)) {
        temAcao = true;
        break;
      }
    }

    // Retorna e "cacheia" (em cache imutável, só pra leitura)
    // Nota: em Dart, Map const não permite update; em produção,
    // usar mutable Map se cache crescer demais (pode-se usar LRU).
    return temAcao;
  }

  List<AppScreen> get visibleScreens => AppScreen.values.where((s) => canView(s)).toList();

  List<AppScreen> get visibleSidebarScreens => [
    AppScreen.logins, AppScreen.comunicados, AppScreen.regimeTributario,
    AppScreen.empresas, AppScreen.parceiros, AppScreen.setores,
    AppScreen.contasPagar, AppScreen.contasReceber, AppScreen.chamados,
    AppScreen.formasPagamento, AppScreen.diretorios, AppScreen.arquivos,
    AppScreen.calendario, AppScreen.obrigacoesFiscais, AppScreen.pedidos,
    AppScreen.configuracoesAdmin, AppScreen.contasBancarias, AppScreen.contaBancaria,
    AppScreen.dashboard, AppScreen.feriados, AppScreen.funcionarios,
    AppScreen.kanbanChamados, AppScreen.nfeEntrada, AppScreen.nfeSaida, AppScreen.pdvNfce, AppScreen.configFiscal,
    AppScreen.pontoWeb, AppScreen.solicitacaoAjustePonto, AppScreen.ajustePonto,
    AppScreen.noticias, AppScreen.perfil, AppScreen.roles,
    AppScreen.produto, AppScreen.unidadeMedida, AppScreen.catalogoProduto, AppScreen.nfeSerie,
    AppScreen.tipoParceiro, AppScreen.servicoContratado, AppScreen.moduloServico,
    AppScreen.trading,
  ].where((s) => canView(s)).toList();

  List<AppScreen> get visibleDashboardWidgets => [
    AppScreen.dashKpis, AppScreen.dashFinanceCards, AppScreen.dashFluxoDiario,
    AppScreen.dashTendenciaFinanceira, AppScreen.dashDistribuicaoClientes,
    AppScreen.dashComparativoTrimestral, AppScreen.dashAlertas,
    AppScreen.dashChamadosCards, AppScreen.dashChamadosPie,
    AppScreen.dashTendenciaChamados, AppScreen.dashChatsLinha,
    AppScreen.dashChatsDiario, AppScreen.dashSaldoContas, AppScreen.dashEvolucaoSaldos,
  ].where((s) => canView(s)).toList();

  @override
  String toString() => 'SecurityMatrix(profile: $profile, tipo: $tipoLogin, app: $aplicativoNome, backendPerms: ${_backendPerms.length} telas)';
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Controle de Acesso por Modulo Contratado
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, Set<AppScreen>> _moduloToScreens = {
  'Financeiro': {
    AppScreen.contasPagar, AppScreen.contasReceber, AppScreen.contasBancarias,
    AppScreen.contaBancaria, AppScreen.formasPagamento, AppScreen.trading,
    AppScreen.dashFinanceCards, AppScreen.dashFluxoDiario,
    AppScreen.dashTendenciaFinanceira, AppScreen.dashComparativoTrimestral,
    AppScreen.dashSaldoContas, AppScreen.dashEvolucaoSaldos,
    // Fase 171 — dashboard de área Financeiro reaproveita o mesmo módulo já
    // usado pelo dashboard financeiro legado (Tarefa F3a do PLAN.md).
    AppScreen.dashFinanceiroArea,
    // Dashboard de mensalidades do escritorio (contaReceber MENS-/MOD-)
    AppScreen.dashMensalidadeArea,
  },
  'Notas Fiscais': {
    AppScreen.nfeEntrada, AppScreen.nfeSaida, AppScreen.pdvNfce, AppScreen.configFiscal, AppScreen.obrigacoesFiscais,
    AppScreen.produto, AppScreen.unidadeMedida, AppScreen.catalogoProduto, AppScreen.nfeSerie,
    AppScreen.dashFiscalArea,
  },
  'Departamento Pessoal': {
    AppScreen.ponto, AppScreen.pontoWeb, AppScreen.solicitacaoAjustePonto,
    AppScreen.ajustePonto, AppScreen.funcionarios, AppScreen.feriados,
    AppScreen.dashDpArea,
  },
  'Chamados': {
    AppScreen.chamados, AppScreen.kanbanChamados,
    AppScreen.dashChamadosCards, AppScreen.dashChamadosPie, AppScreen.dashTendenciaChamados,
    AppScreen.dashAtendimentoArea,
  },
  'Financeiro Limitado': {
    AppScreen.contasPagar,
  },
  'Comunicados': { AppScreen.comunicados },
  'Chat': { AppScreen.chat, AppScreen.dashChatsLinha, AppScreen.dashChatsDiario },
  'GED': { AppScreen.ged, AppScreen.diretorios, AppScreen.arquivos },
  'Dashboard': { AppScreen.dashboard, AppScreen.dashKpis, AppScreen.dashAlertas, AppScreen.dashDistribuicaoClientes },
  // Modulo NFS-e separado de 'Notas Fiscais' (produto). Keystone [P0][ARQUITETURA].
  'NFS-e': {
    AppScreen.nfse,
    AppScreen.obrigacoesFiscais,
  },
  // Card #219 — módulo Comercial: telas mínimas para o cliente criar nota de venda.
  // pdvNfce duplicado intencionalmente com 'Notas Fiscais' (OR logic em isScreenAllowed).
  'Comercial': {
    AppScreen.parceiros,
    AppScreen.produto,
    AppScreen.unidadeMedida,
    AppScreen.catalogoProduto,
    AppScreen.pedidos,
    AppScreen.pdvNfce,
    AppScreen.formasPagamento,
    AppScreen.dashComercialArea,
  },
};

class ModuloAccess {
  static List<String> _modulosContratados = [];
  static List<String> get modulosContratados => _modulosContratados;
  static bool _loaded = false;

  static Future<void> load() async {
    final login = AuthUtility.userInfo?.login;
    final parceiroId = login?.parceiro?.id;
    final empresaId = login?.empresa?.id;
    final tipoLogin = login?.tipoLogin;

    if (tipoLogin == LoginEnum.MASTER) {
      _modulosContratados = _moduloToScreens.keys.toList();
      _loaded = true;
      return;
    }
    final token = AuthUtility.userInfo?.token;
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    Set<String> empresaModulos = {};
    Set<String> parceiroModulos = {};

    if (empresaId != null) {
      try {
        final url = '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=$empresaId';
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(resp.body);
          empresaModulos = data.map((m) => m['nome']?.toString() ?? '').toSet();
        }
      } catch (_) {}
    }

    if (parceiroId != null) {
      try {
        final url = '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId';
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(resp.body);
          parceiroModulos = data.map((m) => m['nome']?.toString() ?? '').toSet();
        }
      } catch (_) {}
    }

    if (empresaModulos.isNotEmpty && parceiroModulos.isNotEmpty) {
      _modulosContratados = empresaModulos.intersection(parceiroModulos).toList();
    } else if (empresaModulos.isNotEmpty) {
      _modulosContratados = empresaModulos.toList();
    } else if (parceiroModulos.isNotEmpty) {
      _modulosContratados = parceiroModulos.toList();
    } else {
      _modulosContratados = _moduloToScreens.keys.toList();
    }
    if (_modulosContratados.isNotEmpty && !_modulosContratados.contains('Financeiro')) {
      _modulosContratados.add('Financeiro Limitado');
    }
    _loaded = true;
  }

  static bool isScreenAllowed(AppScreen screen) {
    if (!_loaded) return true;
    if (_modulosContratados.isEmpty) return true;

    bool pertenceAAlgumModulo = false;
    for (final entry in _moduloToScreens.entries) {
      if (entry.value.contains(screen)) {
        pertenceAAlgumModulo = true;
        if (_modulosContratados.contains(entry.key)) return true;
      }
    }
    if (!pertenceAAlgumModulo) return true;
    return false;
  }

  static bool isModuloContratado(String nome) =>
      _loaded && _modulosContratados.contains(nome);

  static List<AppScreen> filter(List<AppScreen> screens) =>
      screens.where((s) => isScreenAllowed(s)).toList();

  static void reset() { _modulosContratados = []; _loaded = false; }

  /// Define os módulos contratados diretamente, sem chamada de rede — só
  /// para testes unitários de SecurityMatrix/ModuloAccess (Tarefa F4, Fase
  /// 171). Nunca usar em código de produção.
  @visibleForTesting
  static void setContratadosParaTeste(List<String> modulos) {
    _modulosContratados = modulos;
    _loaded = true;
  }
}
