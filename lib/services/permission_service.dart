import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

/// Serviço para filtrar menu baseado em permissões da role
/// Backend envia RolePermissaoDTO com telaNome + podeVer
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() => _instance;

  PermissionService._internal();

  /// Cache de permissões do login atual
  List<RolePermissaoItem>? _currentPermissoes;

  /// Atualizar permissões (chamado após login)
  void setPermissoes(List<RolePermissaoItem>? permissoes) {
    _currentPermissoes = permissoes ?? [];
  }

  /// Verificar se uma tela é visível para o usuário
  bool canViewScreen(String menuItemId) {
    if (_currentPermissoes == null || _currentPermissoes!.isEmpty) {
      return false; // Sem permissões = acesso negado
    }

    final telaNome = _getTelaNomeForMenuItem(menuItemId);
    if (telaNome == null) {
      // MenuItem não mapeado para telaNome — denegar por padrão
      return false;
    }

    // Procurar permissão correspondente
    return _currentPermissoes!.any(
      (perm) => perm.telaNome.toLowerCase() == telaNome.toLowerCase() && perm.podeVer,
    );
  }

  /// Verificar permissões detalhadas para um menuItem
  RolePermissaoItem? getPermission(String menuItemId) {
    if (_currentPermissoes == null) return null;

    final telaNome = _getTelaNomeForMenuItem(menuItemId);
    if (telaNome == null) return null;

    return _currentPermissoes!.firstWhereOrNull(
      (perm) => perm.telaNome.toLowerCase() == telaNome.toLowerCase(),
    );
  }

  /// Filtrar todos os MenuGroups removendo itens não permitidos
  List<MenuGroup> getFilteredMenuGroups() {
    return MenuConfig.groups
        .map((group) => MenuGroup(
              id: group.id,
              label: group.label,
              icon: group.icon,
              items: group.items
                  .where((item) => canViewScreen(item.id))
                  .toList(),
            ))
        .where((group) => group.items.isNotEmpty)
        .toList();
  }

  /// Filtrar itens soltos (loose items)
  List<MenuItem> getFilteredLooseItems() {
    return MenuConfig.loose
        .where((item) => canViewScreen(item.id))
        .toList();
  }

  /// Mapeamento de MenuItem.id → telaNome do backend
  /// Mapeia cada menu item para seu correspondente no backend
  static const Map<String, String> _menuIdToTelaNome = {
    // Comercial
    'nfe_entrada': 'NFeEntrada',
    'nfe_finalidade': 'NfeFinalidade',
    'nfe_import_csv': 'NfeImportCSV',
    'nfe_import_xml': 'NfeImportXml',
    'nfe_saida': 'NFeSaida',
    'nfe_serie': 'NfeSerie',
    'nfe_tipo_operacao': 'NfeTipoOperacao',
    'planos': 'Planos',
    'tipo_parceiro': 'TipoParceiro',
    'servicos_contratados': 'ServicoContratado',
    'modulos_servicos': 'ModuloServico',
    'orcamentos': 'Orcamentos',
    'pedidos_venda': 'PedidosVenda',
    'pedidos_compra': 'PedidosCompra',
    'aprovacao_compra': 'AprovacaoCompra',
    'tabela_preco': 'TabelaPreco',
    'devolucoes': 'Devolucoes',
    'dashboard_comercial': 'DashboardComercial',

    // Fiscal / NFC-e
    'pdv_nfce': 'PdvNfce',
    'config_fiscal': 'ConfigFiscal',
    'consulta_dfe': 'ConsultaDfe',
    'manifestacao_destinatario': 'ManifestacaoDestinatario',
    'nfse': 'Nfse',
    'cancelamento_cce': 'CancelamentoCCe',
    'dashboard_fiscal': 'DashboardFiscal',

    // Financeiro
    'calendario': 'Calendario',
    'calendario_guias': 'CalendarioGuias',
    'conta_bancaria': 'ContaBancaria',
    'contas_pagar': 'ContasPagar',
    'contas_receber': 'ContasReceber',
    'formas_pagamento': 'FormasPagamento',
    'centros_custo': 'CentrosCusto',
    'categorias_financeiras': 'CategoriasFinanceiras',
    'dashboard_financeiro': 'DashboardFinanceiro',
    'dashMensalidadeArea': 'DashboardMensalidades',
    'lancamentos_financeiros': 'LancamentosFinanceiros',
    'importar_extrato': 'ImportarExtrato',
    'importar_boletos_lote': 'ImportarBoletosLote',
    'conciliacao_bancaria': 'ConciliacaoBancaria',
    'integracoes_financeiras': 'IntegracoesFinanceiras',
    'rateio_financeiro': 'RateioFinanceiro',
    'aprovacao_pagamento': 'AprovacaoPagamentos',
    'baixa_automatica': 'BaixaAutomaticaRecebiveis',
    'cobranca': 'Cobranca',
    'renegociacao': 'Renegociacao',
    'dre_gerencial': 'Dre',
    'cobranca_automatica': 'CobrancaAutomatica',
    'kanban_pagamentos': 'KanbanPagamentos',
    'aprovacao_pagamentos_web': 'AprovacaoPagamentos',

    // Depto. Pessoal
    'ajuste_ponto': 'AjustePonto',
    'feriados': 'Feriados',
    'funcionario': 'Funcionarios',
    'ponto': 'Ponto',
    'setores': 'Setores',
    'solicitar_ajuste': 'SolicitarAjuste',
    'dashboard_dp': 'DashboardDP',

    // Suporte / Comunicação
    'chat': 'Chat',
    'comunicados': 'Comunicado',
    'chamados': 'Chamados',
    'diretorios': 'Diretorios',
    'ged': 'Arquivos',
    'noticias': 'Noticias',
    'kanban': 'Kanban',
    'kanban_chat': 'KanbanChat',
    'instagram_monitor': 'InstagramMonitor',

    // Contábil
    'conta_contabil': 'ContaContabil',
    'lancamento_contabil': 'LancamentoContabil',
    'balancete': 'Balancete',
    'fechamento_periodo': 'FechamentoPeriodo',
    'ai_dashboard': 'AiDashboard',
    'ai_assistente': 'AiAssistente',

    // Produtos
    'catalogo_produto': 'CatalagoProduto',
    'produtos': 'Produtos',
    'unidade_medida': 'UnidadeMedida',
    'reserva_estoque': 'ReservaEstoque',
    'multi_deposito': 'MultiDeposito',

    // Configurações
    'logins': 'Logins',
    'solicitacoes_acesso': 'SolicitacoesAcesso',
    'obrigacoes_fiscais': 'ObrigacoesFiscais',
    'regime_tributario': 'Regime',
    'roles': 'Permissoes', // Backend pode usar 'Permissoes' ou 'Roles'
    'alvaras': 'Alvaras',

    // Sistema
    'aplicativo': 'Aplicativo',
    'cadastro_empresa': 'CadastroEmpresa',
    'config_admin': 'ConfigAdmin',
    'config_sistema': 'ConfigSistema',
    'editor_telas': 'EditorTelas',
    'empresas': 'Empresas',
    'permissoes': 'Permissoes',
    'teste_endpoints': 'Teste',
    'query_builder': 'QueryBuilder',

    // App Academia
    'academia': 'Academia',
    'alimentos': 'Alimentos',
    'avaliacao_fisica': 'AvaliacaoFisica',
    'dietas': 'Dietas',
    'exercicios': 'Exercicios',
    'grupos_musculares': 'GruposMusculares',
    'medicamentos': 'Medicamentos',
    'modalidades': 'Modalidades',
    'objetivos': 'Objetivos',
    'personais': 'Personais',
    'suplementos': 'Suplementos',
    'treino': 'Treino',

    // Bolsa de Valores
    'trading_painel': 'TradingPainel',
    'trading_sinais': 'Sinais',
    'trading_oportunidades': 'Oportunidades',
    'trading_watchlist': 'Watchlist',
    'trading_alertas': 'AlertasPreco',
    'trading_operacoes': 'OperacoesAssistidas',
    'trading_backtest': 'Backtest',
    'trading_corretora': 'TradingCorretora',
    'trading_carteira': 'MinhaCarteira',

    // GME
    'dashboard_gme': 'DashboardGME',
    'contrato': 'Contratos',
    'equipamento': 'Equipamentos',
    'ordem_servico': 'OrdensServico',
    'plano_manutencao': 'PlanosManutencao',
    'horimetro': 'Horimetro',
    'historico_manutencao': 'HistoricoManutencao',
    'tecnico_manutencao': 'TecnicosManutencao',

    // Service Desk
    'dashboard_service': 'DashboardService',
    'sla': 'SLA',
    'fila_atendimento': 'FilasAtendimento',
    'categoria_chamado': 'CategoriaChamado',
    'chamado_avaliacao': 'AvaliacaoChamado',

    // Projetos
    'dashboard_projetos': 'DashboardProjetos',
    'projeto': 'Projetos',
    'projeto_etapa': 'ProjetoEtapas',
    'projeto_recurso': 'ProjetoRecursos',
    'projeto_apontamento': 'ProjetoApontamentos',
    'projeto_medicao': 'ProjetoMedicoes',
    'cargo_recurso': 'CargosRecursos',

    // Precificação
    'dashboard_precificacao': 'DashboardPrecificacao',
    'precificacao': 'Precificacoes',
    'custo_direto': 'CustosDiretos',
    'mao_de_obra': 'MaoDobra',
    'precificacao_servico': 'PrecificacaoServicos',
    'condicao_pagamento': 'CondicaoPagamento',
    'proposta_comercial': 'PropostaComercial',

    // Soltos
    'dashboard': 'Dashboard',
    'mensalidades': 'Mensalidades',
    'parceiros': 'Parceiros',
    'pedidos': 'Pedidos',
    'fornecedores': 'Fornecedores',
  };

  /// Obter telaNome para um menuItem.id
  static String? _getTelaNomeForMenuItem(String menuItemId) {
    return _menuIdToTelaNome[menuItemId];
  }

  /// Limpar cache (logout)
  void clear() {
    _currentPermissoes = null;
  }
}

extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
