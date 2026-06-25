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
  calendario,
  chat,
  comunicados,
  chamados,
  ged,
  // Mobile – Menu Mais
  contasPagar,
  contasReceber,
  parceiros,
  dashboard,
  contasBancarias,
  ponto,
  funcionarios,
  // Dashboard widgets
  dashKpis,
  dashFinanceCards,
  dashFluxoDiario,
  dashTendenciaFinanceira,
  dashDistribuicaoClientes,
  dashComparativoTrimestral,
  dashAlertas,
  dashChamadosCards,
  dashChamadosPie,
  dashTendenciaChamados,
  dashChatsLinha,
  dashChatsDiario,
  dashSaldoContas,
  dashEvolucaoSaldos,
  // Web / Windows – Sidebar
  noticias,
  logins,
  cotacao,
  trading,
  comprar,
  aplicativo,
  vender,
  perfil,
  regimeTributario,
  alimentos,
  dietas,
  empresas,
  exames,
  exercicios,
  gruposMusculares,
  medicamentos,
  mensalidades,
  modalidades,
  objetivos,
  personais,
  planos,
  roles,
  setores,
  suplementos,
  formasPagamento,
  diretorios,
  arquivos,
  obrigacoesFiscais,
  // Novas telas
  pedidos,
  configuracoesAdmin,
  contaBancaria,
  feriados,
  kanbanChamados,
  nfeEntrada,
  nfeSaida,
  // Ponto web
  pontoWeb,
  solicitacaoAjustePonto,
  ajustePonto,
  // Admin sistema — só ROLE_SYSTEM
  configSistema,
  // Novas telas cadastro
  tipoParceiro,
  servicoContratado,
  moduloServico,
  // Produto
  produto,
  // Cadastros auxiliares NF-e e produto
  unidadeMedida,
  catalogoProduto,
  nfeSerie,
  pdvNfce,
  configFiscal,
  // Dashboards por área (Fase 171 — fundação)
  dashAtendimentoArea,
  dashFinanceiroArea,
  dashComercialArea,
  dashDpArea,
  dashFiscalArea,
  // NFS-e (nota de serviço) — telas do módulo NFS-e do cliente (a construir).
  nfseEmitir,
  nfseLista,
  nfseSerie,
  servicos,
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Ações
// ─────────────────────────────────────────────────────────────────────────────
// `baixar` (Tarefa keystone "Acesso por Módulo"): ação de quitar título, usada
// no modo Financeiro limitado (cliente sem o módulo Financeiro pode ver+baixar
// Contas a Pagar, mas não inserir/editar/excluir).
enum AppAction { view, insert, update, delete, baixar }

// ─────────────────────────────────────────────────────────────────────────────
// 3. Perfis (mantidos para compatibilidade com código legado)
// ─────────────────────────────────────────────────────────────────────────────
enum UserProfile {
  system,
  escritorio,
  gerente,
  financeiro,
  faturista,
  ponto,
  semAcesso,
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Mapeamento role.key → UserProfile
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, UserProfile> _roleKeyToProfile = {
  'ROLE_SYSTEM': UserProfile.system,
  'ROLE_ESCRITORIO': UserProfile.escritorio,
  'ROLE_GERENTE': UserProfile.gerente,
  'ROLE_FINANCEIRO': UserProfile.financeiro,
  'ROLE_FATURISTA': UserProfile.faturista,
  'ROLE_PONTO': UserProfile.ponto,
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. Atalhos
// ─────────────────────────────────────────────────────────────────────────────
const _all = {
  AppAction.view,
  AppAction.insert,
  AppAction.update,
  AppAction.delete
};
const _ro = {AppAction.view};

// Telas do ESCRITORIO (fallback hardcoded)
const _escritorioScreens = {
  AppScreen.logins: _all,
  AppScreen.comunicados: _all,
  AppScreen.regimeTributario: _all,
  AppScreen.empresas: _all,
  AppScreen.parceiros: _all,
  AppScreen.setores: _all,
  AppScreen.produto: _all,
  AppScreen.unidadeMedida: _all,
  AppScreen.catalogoProduto: _all,
  AppScreen.nfeSerie: _all,
  AppScreen.contasPagar: _all,
  AppScreen.contasReceber: _all,
  AppScreen.trading: _ro,
  AppScreen.chamados: _all,
  AppScreen.formasPagamento: _all,
  AppScreen.diretorios: _all,
  AppScreen.arquivos: _all,
  AppScreen.calendario: _all,
  AppScreen.obrigacoesFiscais: _all,
  AppScreen.pedidos: _all,
  AppScreen.configuracoesAdmin: _all,
  AppScreen.contasBancarias: _all,
  AppScreen.contaBancaria: _all,
  AppScreen.dashboard: _ro,
  AppScreen.feriados: _all,
  AppScreen.funcionarios: _all,
  AppScreen.kanbanChamados: _all,
  AppScreen.nfeEntrada: _all,
  AppScreen.nfeSaida: _all,
  AppScreen.pdvNfce: _all,
  AppScreen.configFiscal: _all,
  AppScreen.dashKpis: _ro,
  AppScreen.dashFinanceCards: _ro,
  AppScreen.dashFluxoDiario: _ro,
  AppScreen.dashTendenciaFinanceira: _ro,
  AppScreen.dashDistribuicaoClientes: _ro,
  AppScreen.dashComparativoTrimestral: _ro,
  AppScreen.dashAlertas: _ro,
  AppScreen.dashChamadosCards: _ro,
  AppScreen.dashChamadosPie: _ro,
  AppScreen.dashTendenciaChamados: _ro,
  AppScreen.dashChatsLinha: _ro,
  AppScreen.dashChatsDiario: _ro,
  AppScreen.dashSaldoContas: _ro,
  AppScreen.dashEvolucaoSaldos: _ro,
  AppScreen.dashAtendimentoArea: _ro,
  AppScreen.dashFinanceiroArea: _ro,
  AppScreen.dashComercialArea: _ro,
  AppScreen.dashDpArea: _ro,
  AppScreen.dashFiscalArea: _ro,
  AppScreen.ponto: _all,
  AppScreen.pontoWeb: _all,
  AppScreen.solicitacaoAjustePonto: _all,
  AppScreen.ajustePonto: _all,
  AppScreen.ged: _all,
  AppScreen.chat: _all,
  AppScreen.perfil: _all,
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. Matriz fallback (hardcoded — usada quando backend não retorna permissões)
// ─────────────────────────────────────────────────────────────────────────────
final Map<UserProfile, Map<AppScreen, Set<AppAction>>> _fallbackMatrix = {
  UserProfile.system: {for (final s in AppScreen.values) s: _all},
  UserProfile.escritorio: _escritorioScreens,
  UserProfile.gerente: {
    ..._escritorioScreens,
    AppScreen.regimeTributario: const {}
  },
  UserProfile.financeiro: {
    AppScreen.parceiros: _all,
    AppScreen.formasPagamento: _all,
    AppScreen.trading: _ro,
    AppScreen.diretorios: _all,
    AppScreen.arquivos: _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria: _all,
    AppScreen.contasPagar: _all,
    AppScreen.contasReceber: _all,
    AppScreen.nfeEntrada: _all,
    AppScreen.nfeSaida: _all,
    AppScreen.pdvNfce: _all,
    AppScreen.configFiscal: _all,
    AppScreen.dashboard: _ro,
    AppScreen.dashKpis: _ro,
    AppScreen.dashFinanceCards: _ro,
    AppScreen.dashFluxoDiario: _ro,
    AppScreen.dashTendenciaFinanceira: _ro,
    AppScreen.dashDistribuicaoClientes: _ro,
    AppScreen.dashComparativoTrimestral: _ro,
    AppScreen.dashAlertas: _ro,
    AppScreen.dashSaldoContas: _ro,
    AppScreen.dashEvolucaoSaldos: _ro,
    AppScreen.noticias: _ro,
    AppScreen.perfil: _all,
    AppScreen.calendario: _ro,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb: {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
  },
  UserProfile.faturista: {
    AppScreen.empresas: _ro,
    AppScreen.parceiros: _all,
    AppScreen.produto: _all,
    AppScreen.unidadeMedida: _all,
    AppScreen.catalogoProduto: _all,
    AppScreen.nfeSerie: _all,
    AppScreen.formasPagamento: _all,
    AppScreen.diretorios: _all,
    AppScreen.arquivos: _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria: _all,
    AppScreen.contasPagar: _all,
    AppScreen.contasReceber: _all,
    AppScreen.nfeEntrada: _all,
    AppScreen.nfeSaida: _all,
    AppScreen.pdvNfce: _all,
    AppScreen.configFiscal: _all,
    AppScreen.noticias: _ro,
    AppScreen.perfil: _all,
    AppScreen.calendario: _ro,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb: {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat: _ro,
    AppScreen.comunicados: _ro,
    AppScreen.chamados: _all,
    AppScreen.ged: _all,
  },
  UserProfile.ponto: {
    AppScreen.calendario: _ro,
    AppScreen.ponto: {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb: {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat: _ro,
    AppScreen.comunicados: _ro,
    AppScreen.noticias: _ro,
    AppScreen.perfil: _ro,
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

  const SecurityMatrix._({
    required this.profile,
    this.tipoLogin,
    this.aplicativoNome,
    Map<String, Set<AppAction>> backendPerms = const {},
  }) : _backendPerms = backendPerms;

  factory SecurityMatrix.of(LoginModel? userInfo) {
    if (userInfo == null)
      return const SecurityMatrix._(profile: UserProfile.semAcesso);

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
      UserProfile.system,
      UserProfile.escritorio,
      UserProfile.gerente,
      UserProfile.financeiro,
      UserProfile.faturista,
      UserProfile.ponto,
    ];
    for (final p in priority) {
      final key = _roleKeyToProfile.entries
          .firstWhere((e) => e.value == p,
              orElse: () => const MapEntry('', UserProfile.semAcesso))
          .key;
      if (roles.any((r) => r.key == key)) {
        resolved = p;
        break;
      }
    }
    if (resolved == UserProfile.semAcesso && roles.isNotEmpty)
      resolved = UserProfile.escritorio;
    if (resolved == UserProfile.semAcesso && tipoLogin != null)
      resolved = UserProfile.escritorio;

    // Constrói mapa de permissões do backend (consolidado por tela — OR entre roles)
    final backendPerms = <String, Set<AppAction>>{};
    if (userInfo.permissoes != null && userInfo.permissoes!.isNotEmpty) {
      for (final p in userInfo.permissoes!) {
        final existing = backendPerms[p.telaNome] ?? <AppAction>{};
        if (p.podeVer) existing.add(AppAction.view);
        if (p.podeInserir) existing.add(AppAction.insert);
        if (p.podeEditar) existing.add(AppAction.update);
        if (p.podeDeletar) existing.add(AppAction.delete);
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

    // Se backend retornou permissões, usa elas
    if (_backendPerms.isNotEmpty) {
      final perms = _backendPerms[screen.name];
      if (perms == null) return false;
      return perms.contains(action) &&
          ModuloAccess.isScreenAllowed(screen) &&
          ModuloAccess.isActionAllowed(screen, action);
    }

    // Fallback: matrix hardcoded
    final hasRole =
        _fallbackMatrix[profile]?[screen]?.contains(action) ?? false;
    if (!hasRole) return false;
    return ModuloAccess.isScreenAllowed(screen) &&
        ModuloAccess.isActionAllowed(screen, action);
  }

  bool canView(AppScreen screen) => _can(screen, AppAction.view);
  bool canInsert(AppScreen screen) => _can(screen, AppAction.insert);
  bool canUpdate(AppScreen screen) => _can(screen, AppAction.update);
  bool canDelete(AppScreen screen) => _can(screen, AppAction.delete);

  /// Pode dar BAIXA (quitar título) na tela. O backend ainda não modela `baixar`
  /// em role_permissao (follow-up), então deriva da visibilidade + regra de
  /// módulo: quem vê a tela e não está bloqueado por módulo pode baixar. No modo
  /// Financeiro limitado, `isActionAllowed` libera `baixar` em Contas a Pagar.
  bool canBaixar(AppScreen screen) {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return ModuloAccess.isScreenAllowed(screen);
    }
    return canView(screen) &&
        ModuloAccess.isActionAllowed(screen, AppAction.baixar);
  }

  /// True quando o usuário está no modo "Financeiro limitado": vê Contas a Pagar
  /// (consulta + baixa) mas NÃO tem o módulo Financeiro completo (sem inserir,
  /// sem Contas a Receber). Usado para microcopy/empty state explicativos —
  /// derivado da engine (vê a tela mas não pode inserir).
  bool get isFinanceiroLimitado {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return false;
    }
    return canView(AppScreen.contasPagar) && !canInsert(AppScreen.contasPagar);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Enforcement por telaNome canônico (= MenuConfig.id). Independe do enum
  // AppScreen (que cobre só parte das telas). Usado pelo filtro do menu lateral.
  // ───────────────────────────────────────────────────────────────────────────

  /// MASTER/SYSTEM têm acesso total e ignoram o filtro de permissões.
  bool get isMaster =>
      profile == UserProfile.system || tipoLogin == LoginEnum.MASTER;

  /// IDs de tela (telaNome) que o usuário pode VISUALIZAR, vindas do backend.
  Set<String> get viewableTelaIds {
    final result = <String>{};
    _backendPerms.forEach((tela, actions) {
      if (actions.contains(AppAction.view)) result.add(tela);
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
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER)
      return true;
    return hasRoleKey('ROLE_ADMIN') || hasRoleKey('ROLE_FISCAL');
  }

  bool hasAnyAccess(AppScreen screen) {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER)
      return true;
    if (_backendPerms.isNotEmpty)
      return (_backendPerms[screen.name]?.isNotEmpty) ?? false;
    return (_fallbackMatrix[profile]?[screen]?.isNotEmpty) ?? false;
  }

  List<AppScreen> get visibleScreens =>
      AppScreen.values.where((s) => canView(s)).toList();

  List<AppScreen> get visibleSidebarScreens => [
        AppScreen.logins,
        AppScreen.comunicados,
        AppScreen.regimeTributario,
        AppScreen.empresas,
        AppScreen.parceiros,
        AppScreen.setores,
        AppScreen.contasPagar,
        AppScreen.contasReceber,
        AppScreen.chamados,
        AppScreen.formasPagamento,
        AppScreen.diretorios,
        AppScreen.arquivos,
        AppScreen.calendario,
        AppScreen.obrigacoesFiscais,
        AppScreen.pedidos,
        AppScreen.configuracoesAdmin,
        AppScreen.contasBancarias,
        AppScreen.contaBancaria,
        AppScreen.dashboard,
        AppScreen.feriados,
        AppScreen.funcionarios,
        AppScreen.kanbanChamados,
        AppScreen.nfeEntrada,
        AppScreen.nfeSaida,
        AppScreen.pdvNfce,
        AppScreen.configFiscal,
        AppScreen.pontoWeb,
        AppScreen.solicitacaoAjustePonto,
        AppScreen.ajustePonto,
        AppScreen.noticias,
        AppScreen.perfil,
        AppScreen.roles,
        AppScreen.produto,
        AppScreen.unidadeMedida,
        AppScreen.catalogoProduto,
        AppScreen.nfeSerie,
        AppScreen.tipoParceiro,
        AppScreen.servicoContratado,
        AppScreen.moduloServico,
        AppScreen.trading,
      ].where((s) => canView(s)).toList();

  List<AppScreen> get visibleDashboardWidgets => [
        AppScreen.dashKpis,
        AppScreen.dashFinanceCards,
        AppScreen.dashFluxoDiario,
        AppScreen.dashTendenciaFinanceira,
        AppScreen.dashDistribuicaoClientes,
        AppScreen.dashComparativoTrimestral,
        AppScreen.dashAlertas,
        AppScreen.dashChamadosCards,
        AppScreen.dashChamadosPie,
        AppScreen.dashTendenciaChamados,
        AppScreen.dashChatsLinha,
        AppScreen.dashChatsDiario,
        AppScreen.dashSaldoContas,
        AppScreen.dashEvolucaoSaldos,
      ].where((s) => canView(s)).toList();

  /// Retorna `true` se o usuário pode visualizar dados sensíveis como
  /// remuneração/salário de funcionários (Módulo Departamento Pessoal).
  /// Regra: apenas SYSTEM, ESCRITORIO e GERENTE têm acesso a dados salariais.
  bool get canViewRemuneracao {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER)
      return true;
    return profile == UserProfile.escritorio || profile == UserProfile.gerente;
  }

  @override
  String toString() =>
      'SecurityMatrix(profile: $profile, tipo: $tipoLogin, app: $aplicativoNome, backendPerms: ${_backendPerms.length} telas)';
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Controle de Acesso por Modulo Contratado
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, Set<AppScreen>> _moduloToScreens = {
  'Financeiro': {
    AppScreen.contasPagar,
    AppScreen.contasReceber,
    AppScreen.contasBancarias,
    AppScreen.contaBancaria,
    AppScreen.formasPagamento,
    AppScreen.dashFinanceCards,
    AppScreen.dashFluxoDiario,
    AppScreen.dashTendenciaFinanceira,
    AppScreen.dashComparativoTrimestral,
    AppScreen.dashSaldoContas,
    AppScreen.dashEvolucaoSaldos,
  },
  'Notas Fiscais': {
    AppScreen.nfeEntrada,
    AppScreen.nfeSaida,
    AppScreen.pdvNfce,
    AppScreen.configFiscal,
    AppScreen.obrigacoesFiscais,
    AppScreen.produto,
    AppScreen.unidadeMedida,
    AppScreen.catalogoProduto,
    AppScreen.nfeSerie,
  },
  'Departamento Pessoal': {
    AppScreen.ponto, AppScreen.pontoWeb, AppScreen.solicitacaoAjustePonto,
    AppScreen.ajustePonto, AppScreen.funcionarios, AppScreen.feriados,
    // Fase 171 — dashDpArea entra no mesmo módulo 'Departamento Pessoal' já
    // existente (confirmado no RESEARCH desta fase, Tarefa F3a do PLAN.md).
    AppScreen.dashDpArea,
  },
  // Módulos do cliente (iniciativa "Acesso por Módulo do Cliente").
  // Inclui Clientes (parceiros) e Pedidos de Venda conforme telas mínimas
  // definidas no card jAmXlyaO (Módulo Comercial).
  'Comercial': {
    AppScreen.produto, // Produtos
    AppScreen.parceiros, // Clientes
    AppScreen.pedidos, // Pedido de Venda
    AppScreen.pdvNfce, // PDV/NFC-e
    AppScreen.nfeSaida, // NF-e Saída
    AppScreen.formasPagamento, // Formas de Pagamento
    AppScreen.unidadeMedida, // Unidade de Medida
    AppScreen.catalogoProduto, // Catálogo
    AppScreen.dashComercialArea,
  },
  'NFS-e': {
    AppScreen.nfseEmitir,
    AppScreen.nfseLista,
    AppScreen.nfseSerie,
    AppScreen.servicos,
    AppScreen.configFiscal,
  },
  'Chamados': {
    AppScreen.chamados,
    AppScreen.kanbanChamados,
    AppScreen.dashChamadosCards,
    AppScreen.dashChamadosPie,
    AppScreen.dashTendenciaChamados,
  },
  'Comunicados': {AppScreen.comunicados},
  'Chat': {AppScreen.chat, AppScreen.dashChatsLinha, AppScreen.dashChatsDiario},
  'GED': {AppScreen.ged, AppScreen.diretorios, AppScreen.arquivos},
  'Dashboard': {
    AppScreen.dashboard,
    AppScreen.dashKpis,
    AppScreen.dashAlertas,
    AppScreen.dashDistribuicaoClientes
  },
  // Fase 171 (Tarefa F3b/F3c) — decisão registrada: o RESEARCH não confirma
  // um módulo isolado pré-existente para Atendimento, Comercial ou Fiscal
  // como áreas dedicadas (o legado mistura Atendimento dentro de
  // 'Chamados'/'Chat', e Comercial/Fiscal não têm módulo de dashboard
  // anterior). PERGUNTA A CONFIRMAR (ver MATRIZ-KPI.md e SUMMARY desta
  // fase): dashAtendimentoArea, dashComercialArea e dashFiscalArea ficam
  // FORA de _moduloToScreens nesta fundação — liberados por padrão a quem
  // tiver role_permissao de view (comportamento de "nao pertence a nenhum
  // modulo" já documentado no Pitfall 3 da pesquisa). Os cards dependentes
  // de Atendimento/Comercial/Fiscal devem revisar esta decisão quando
  // tiverem clareza do módulo comercial/contratado correspondente.
};

class ModuloAccess {
  static List<String> _modulosContratados = [];
  static bool _loaded = false;

  /// Expõe a lista de módulos contratados para uso externo (ex: ModulePriority).
  static List<String> get modulosContratados =>
      List.unmodifiable(_modulosContratados);
  static bool get isLoaded => _loaded;

  // Busca os nomes dos módulos de um endpoint (/api/parceiro-modulo ou
  // /api/empresa-modulo). Lista vazia em qualquer falha.
  static Future<List<String>> _fetchModulos(String url) async {
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        return data
            .map((m) => m['nome']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return <String>[];
  }

  /// Semântica (iniciativa "Acesso por Módulo"): EMPRESA = teto.
  ///  - MASTER: todos os módulos.
  ///  - Cliente (tem parceiro): interseção(empresa, parceiro); se a empresa não
  ///    definiu teto, usa só os do parceiro; se o parceiro não restringe, herda
  ///    os da empresa.
  ///  - Escritório/contabilidade (sem parceiro): gateado pelos módulos da empresa.
  /// Lista vazia = SEM gating (mantém compatibilidade: empresa/parceiro ainda
  /// não configurados liberam tudo).
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

    final empresaModulos = empresaId != null
        ? await _fetchModulos(
            '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=$empresaId')
        : <String>[];
    final parceiroModulos = parceiroId != null
        ? await _fetchModulos(
            '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId')
        : <String>[];

    List<String> resultado;
    if (parceiroId != null) {
      if (empresaModulos.isEmpty) {
        resultado = parceiroModulos; // empresa sem teto → só os do parceiro
      } else if (parceiroModulos.isEmpty) {
        resultado = empresaModulos; // parceiro sem restrição → herda o teto
      } else {
        resultado = parceiroModulos
            .where((m) => empresaModulos.contains(m))
            .toList(); // interseção
      }
    } else {
      resultado = empresaModulos; // escritório: só o que a empresa contratou
    }
    _modulosContratados = resultado;
    _loaded = true;
  }

  static bool _temFinanceiro() => _modulosContratados.contains('Financeiro');

  static bool isScreenAllowed(AppScreen screen) {
    if (!_loaded) return true;
    if (_modulosContratados.isEmpty) return true;

    // Acesso mínimo Financeiro: Contas a Pagar fica SEMPRE visível, mesmo sem o
    // módulo Financeiro contratado — em modo consulta + baixa (ver
    // isActionAllowed). Contas a Receber continua escondida (pertence só ao
    // módulo Financeiro). Regra da iniciativa "Acesso por Módulo do Cliente".
    if (screen == AppScreen.contasPagar) return true;

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

  /// Gating por AÇÃO dirigido por módulo (dimensão nova sobre o gating por tela).
  /// Hoje cobre o "Financeiro limitado": sem o módulo Financeiro, Contas a Pagar
  /// é só consulta + baixa (sem inserir/editar/excluir). Semântica RESTRITIVA:
  /// só remove ações, nunca concede além do que a role/backend já permite.
  static bool isActionAllowed(AppScreen screen, AppAction action) {
    if (!_loaded || _modulosContratados.isEmpty) return true;
    if (screen == AppScreen.contasPagar && !_temFinanceiro()) {
      return action == AppAction.view || action == AppAction.baixar;
    }
    return true;
  }

  static List<AppScreen> filter(List<AppScreen> screens) =>
      screens.where((s) => isScreenAllowed(s)).toList();

  static void reset() {
    _modulosContratados = [];
    _loaded = false;
  }

  /// Define os módulos contratados diretamente, sem chamada de rede — só
  /// para testes unitários de SecurityMatrix/ModuloAccess (Tarefa F4, Fase
  /// 171). Nunca usar em código de produção.
  @visibleForTesting
  static void setContratadosParaTeste(List<String> modulos) {
    _modulosContratados = modulos;
    _loaded = true;
  }
}
