import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Definição de um item de menu
class MenuItem {
  final String id;
  final String label;
  final FaIconData icon;
  final int screenIndex; // índice na lista _screens (-1 = não implementado)

  const MenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.screenIndex,
  });
}

/// Grupo de menu (submenu expansível)
class MenuGroup {
  final String id;
  final String label;
  final FaIconData icon;
  final List<MenuItem> items;

  const MenuGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });
}

/// Índices _buildScreens (Web e Windows):
/// 0:Comunicado  1:Chat  2:ComunicadoComp  3:Aplicativo  4:Logins  5:ChatList
/// 6,7:ProductRegister  8:Regime  9:Alimentos  10:Dietas  11:Empresas
/// 12:Exames  13:Exercícios  14:GruposMusculares  15:Medicamentos
/// 16:Mensalidades  17:Modalidades  18:Objetivos  19:Parceiros  20:Personais
/// 21:Planos  22:Roles  23:Setores  24:Suplementos  25:ContasPagar
/// 26:ContasReceber  27:Chamados  28:FormasPagamento  29:Diretorios
/// 30:Arquivos  31:Calendario  32:ObrigacoesFiscais  33:[ORPHAN-era Logins dup]
/// 34:CotacaoFrete  35:CalendarioGuias  36:Tickets  37:Dividendos
/// 38:Ordens  39:Pedidos  40:ConfigAdmin  41:AlertaAluno  42:AvaliacaoFisica
/// 43:ContaBancaria  44:Classificacao  45:Dashboard  46:Feriados
/// 47:NFeEntrada  48:NFeSaida  49:Treino  50:Funcionarios  51:Kanban
/// 52:EditorTelas  53:Produtos
/// 54:NfeFinalidade  55:NfeSerie  56:NfeTipoOperacao  57:UnidadeMedida
/// 58:CatalagoProduto  59:Permissoes  60:Ponto  61:SolicitarAjuste
/// 62:AjustePonto  63:ConfigSistema  64:Chat  65:Teste  66:CadastroEmpresa
/// 67:TipoParceiro  68:ServicoContratado  69:ModuloServico  70:Alvaras  71:NfeImportCSV
/// 72:TradingPainel  73:CRM/Funil  74:AutomacaoFiscal
/// 75:Sinais  76:Oportunidades  77:Watchlist  78:AlertasPreco  79:OperacoesAssistidas
/// 80:PdvNfce  81:ConfigFiscal  82:CentroCusto  83:CategoriaFinanceira  84:AjudaTelas  85:Backtest
/// 86:PortalColaborador  87:DashboardDP  88:EscalasTurnos  89:Ferias
/// 90:AdmissaoDigital  91:Rubricas  92:EventosFolha  93:Beneficios
/// 94:Desligamentos  95:ObrigacoesTrabalhistas

class MenuConfig {
  MenuConfig._();

  static const List<MenuGroup> groups = [
    MenuGroup(
      id: 'app_academia',
      label: 'App Academia',
      icon: FontAwesomeIcons.dumbbell,
      items: [
        MenuItem(
            id: 'alimentos',
            label: 'Alimentos',
            icon: FontAwesomeIcons.appleWhole,
            screenIndex: 9),
        MenuItem(
            id: 'avaliacao_fisica',
            label: 'Avaliação Física',
            icon: FontAwesomeIcons.clipboardList,
            screenIndex: 42),
        MenuItem(
            id: 'dietas',
            label: 'Dietas',
            icon: FontAwesomeIcons.bowlFood,
            screenIndex: 10),
        MenuItem(
            id: 'exercicios',
            label: 'Exercícios',
            icon: FontAwesomeIcons.dumbbell,
            screenIndex: 13),
        MenuItem(
            id: 'grupos_musculares',
            label: 'Grupos Musculares',
            icon: FontAwesomeIcons.peopleGroup,
            screenIndex: 14),
        MenuItem(
            id: 'medicamentos',
            label: 'Medicamentos',
            icon: FontAwesomeIcons.pills,
            screenIndex: 15),
        MenuItem(
            id: 'modalidades',
            label: 'Modalidades',
            icon: FontAwesomeIcons.tableList,
            screenIndex: 17),
        MenuItem(
            id: 'objetivos',
            label: 'Objetivos',
            icon: FontAwesomeIcons.bullseye,
            screenIndex: 18),
        MenuItem(
            id: 'personais',
            label: 'Personais',
            icon: FontAwesomeIcons.userTie,
            screenIndex: 20),
        MenuItem(
            id: 'suplementos',
            label: 'Suplementos',
            icon: FontAwesomeIcons.capsules,
            screenIndex: 24),
        MenuItem(
            id: 'treino',
            label: 'Treino',
            icon: FontAwesomeIcons.personRunning,
            screenIndex: 49),
      ],
    ),
    MenuGroup(
      id: 'comercial',
      label: 'Comercial',
      icon: FontAwesomeIcons.briefcase,
      items: [
        MenuItem(
            id: 'nfe_entrada',
            label: 'NF-e Entrada',
            icon: FontAwesomeIcons.fileImport,
            screenIndex: 47),
        MenuItem(
            id: 'nfe_finalidade',
            label: 'NF-e Finalidade',
            icon: FontAwesomeIcons.fileCircleCheck,
            screenIndex: 54),
        MenuItem(
            id: 'nfe_import_csv',
            label: 'Importar NF-e CSV',
            icon: FontAwesomeIcons.fileCsv,
            screenIndex: 71),
        MenuItem(
            id: 'nfe_saida',
            label: 'NF-e Saída',
            icon: FontAwesomeIcons.fileExport,
            screenIndex: 48),
        MenuItem(
            id: 'nfe_serie',
            label: 'NF-e Série',
            icon: FontAwesomeIcons.hashtag,
            screenIndex: 55),
        MenuItem(
            id: 'nfe_tipo_operacao',
            label: 'NF-e Tipo Operação',
            icon: FontAwesomeIcons.arrowsLeftRight,
            screenIndex: 56),
        MenuItem(
            id: 'planos',
            label: 'Planos',
            icon: FontAwesomeIcons.listCheck,
            screenIndex: 21),
        MenuItem(
            id: 'tipo_parceiro',
            label: 'Tipo de Parceiro',
            icon: FontAwesomeIcons.tags,
            screenIndex: 67),
        MenuItem(
            id: 'servicos_contratados',
            label: 'Serviços Contratados',
            icon: FontAwesomeIcons.fileContract,
            screenIndex: 68),
        MenuItem(
            id: 'modulos_servicos',
            label: 'Módulos/Serviços',
            icon: FontAwesomeIcons.cubes,
            screenIndex: 69),
      ],
    ),
    MenuGroup(
      id: 'fiscal',
      label: 'Fiscal / NFC-e',
      icon: FontAwesomeIcons.cashRegister,
      items: [
        MenuItem(
            id: 'pdv_nfce',
            label: 'PDV / NFC-e',
            icon: FontAwesomeIcons.cashRegister,
            screenIndex: 80),
        MenuItem(
            id: 'config_fiscal',
            label: 'Config. Fiscal',
            icon: FontAwesomeIcons.gear,
            screenIndex: 81),
      ],
    ),
    MenuGroup(
      id: 'suporte_comunicacao',
      label: 'Suporte / Comunicação',
      icon: FontAwesomeIcons.comments,
      items: [
        MenuItem(
            id: 'chat',
            label: 'Chat',
            icon: FontAwesomeIcons.comments,
            screenIndex: 64),
        MenuItem(
            id: 'comunicados',
            label: 'Comunicados',
            icon: FontAwesomeIcons.newspaper,
            screenIndex: 0),
        MenuItem(
            id: 'chamados',
            label: 'Chamados',
            icon: FontAwesomeIcons.ticketSimple,
            screenIndex: 27),
        MenuItem(
            id: 'ged',
            label: 'GED',
            icon: FontAwesomeIcons.folderOpen,
            screenIndex: 30),
        MenuItem(
            id: 'noticias',
            label: 'Notícias',
            icon: FontAwesomeIcons.newspaper,
            screenIndex: 0),
        MenuItem(
            id: 'kanban',
            label: 'Kanban',
            icon: FontAwesomeIcons.trello,
            screenIndex: 51),
      ],
    ),
    MenuGroup(
      id: 'configuracoes',
      label: 'Configurações',
      icon: FontAwesomeIcons.sliders,
      items: [
        MenuItem(
            id: 'logins',
            label: 'Logins',
            icon: FontAwesomeIcons.userLock,
            screenIndex: 4),
        MenuItem(
            id: 'obrigacoes_fiscais',
            label: 'Obrigações Fiscais',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            screenIndex: 32),
        MenuItem(
            id: 'regime_tributario',
            label: 'Regime Tributário',
            icon: FontAwesomeIcons.taxi,
            screenIndex: 8),
        MenuItem(
            id: 'roles',
            label: 'Roles',
            icon: FontAwesomeIcons.userShield,
            screenIndex: 22),
        MenuItem(
            id: 'alvaras',
            label: 'Alvarás',
            icon: FontAwesomeIcons.stamp,
            screenIndex: 70),
      ],
    ),
    MenuGroup(
      id: 'depto_pessoal',
      label: 'Depto. Pessoal',
      icon: FontAwesomeIcons.idCard,
      items: [
        MenuItem(
            id: 'dp_dashboard',
            label: 'Dashboard DP',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 87),
        MenuItem(
            id: 'portal_colaborador',
            label: 'Portal Colaborador',
            icon: FontAwesomeIcons.idBadge,
            screenIndex: 86),
        MenuItem(
            id: 'ajuste_ponto',
            label: 'Ajuste de Ponto',
            icon: FontAwesomeIcons.clockRotateLeft,
            screenIndex: 62),
        MenuItem(
            id: 'dp_admissao',
            label: 'Admissao Digital',
            icon: FontAwesomeIcons.userPlus,
            screenIndex: 90),
        MenuItem(
            id: 'dp_beneficios',
            label: 'Beneficios',
            icon: FontAwesomeIcons.handHoldingHeart,
            screenIndex: 93),
        MenuItem(
            id: 'dp_desligamentos',
            label: 'Desligamentos',
            icon: FontAwesomeIcons.userMinus,
            screenIndex: 94),
        MenuItem(
            id: 'dp_escalas',
            label: 'Escalas e Turnos',
            icon: FontAwesomeIcons.calendarWeek,
            screenIndex: 88),
        MenuItem(
            id: 'dp_eventos_folha',
            label: 'Eventos da Folha',
            icon: FontAwesomeIcons.receipt,
            screenIndex: 92),
        MenuItem(
            id: 'dp_ferias',
            label: 'Ferias',
            icon: FontAwesomeIcons.umbrellaBeach,
            screenIndex: 89),
        MenuItem(
            id: 'dp_obrigacoes_trabalhistas',
            label: 'Obrigacoes Trabalhistas',
            icon: FontAwesomeIcons.fileCircleCheck,
            screenIndex: 95),
        MenuItem(
            id: 'feriados',
            label: 'Feriados',
            icon: FontAwesomeIcons.umbrellaBeach,
            screenIndex: 46),
        MenuItem(
            id: 'funcionarios',
            label: 'Funcionários',
            icon: FontAwesomeIcons.idCard,
            screenIndex: 50),
        MenuItem(
            id: 'ponto',
            label: 'Ponto',
            icon: FontAwesomeIcons.clock,
            screenIndex: 60),
        MenuItem(
            id: 'dp_rubricas',
            label: 'Rubricas da Folha',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            screenIndex: 91),
        MenuItem(
            id: 'setores',
            label: 'Setores',
            icon: FontAwesomeIcons.sitemap,
            screenIndex: 23),
        MenuItem(
            id: 'solicitar_ajuste',
            label: 'Solicitar Ajuste Ponto',
            icon: FontAwesomeIcons.penToSquare,
            screenIndex: 61),
      ],
    ),
    MenuGroup(
      id: 'financeiro',
      label: 'Financeiro',
      icon: FontAwesomeIcons.moneyBillTrendUp,
      items: [
        MenuItem(
            id: 'calendario',
            label: 'Calendário',
            icon: FontAwesomeIcons.calendar,
            screenIndex: 31),
        MenuItem(
            id: 'calendario_guias',
            label: 'Calendário de Guias',
            icon: FontAwesomeIcons.calendarDays,
            screenIndex: 35),
        MenuItem(
            id: 'conta_bancaria',
            label: 'Conta Bancária',
            icon: FontAwesomeIcons.buildingColumns,
            screenIndex: 43),
        MenuItem(
            id: 'contas_pagar',
            label: 'Contas a Pagar',
            icon: FontAwesomeIcons.moneyBill,
            screenIndex: 25),
        MenuItem(
            id: 'contas_receber',
            label: 'Contas a Receber',
            icon: FontAwesomeIcons.moneyCheckDollar,
            screenIndex: 26),
        MenuItem(
            id: 'formas_pagamento',
            label: 'Formas de Pagamento',
            icon: FontAwesomeIcons.creditCard,
            screenIndex: 28),
        MenuItem(
            id: 'centros_custo',
            label: 'Centros de Custo',
            icon: FontAwesomeIcons.sitemap,
            screenIndex: 82),
        MenuItem(
            id: 'categorias_financeiras',
            label: 'Categorias Financeiras',
            icon: FontAwesomeIcons.tags,
            screenIndex: 83),
      ],
    ),
    MenuGroup(
      id: 'produtos',
      label: 'Produtos',
      icon: FontAwesomeIcons.box,
      items: [
        MenuItem(
            id: 'catalogo_produto',
            label: 'Catálogo Produto',
            icon: FontAwesomeIcons.boxOpen,
            screenIndex: 58),
        MenuItem(
            id: 'produtos',
            label: 'Produtos',
            icon: FontAwesomeIcons.box,
            screenIndex: 53),
        MenuItem(
            id: 'unidade_medida',
            label: 'Unidade de Medida',
            icon: FontAwesomeIcons.rulerHorizontal,
            screenIndex: 57),
      ],
    ),
    MenuGroup(
      id: 'bolsa_valores',
      label: 'Bolsa de Valores',
      icon: FontAwesomeIcons.chartLine,
      items: [
        MenuItem(
            id: 'trading_painel',
            label: 'Painel de Trading',
            icon: FontAwesomeIcons.gaugeHigh,
            screenIndex: 72),
        MenuItem(
            id: 'trading_sinais',
            label: 'Sinais de Mercado',
            icon: FontAwesomeIcons.arrowTrendUp,
            screenIndex: 75),
        MenuItem(
            id: 'trading_oportunidades',
            label: 'Oportunidades',
            icon: FontAwesomeIcons.star,
            screenIndex: 76),
        MenuItem(
            id: 'trading_watchlist',
            label: 'Watchlist',
            icon: FontAwesomeIcons.bookmark,
            screenIndex: 77),
        MenuItem(
            id: 'trading_alertas',
            label: 'Alertas de Preço',
            icon: FontAwesomeIcons.bell,
            screenIndex: 78),
        MenuItem(
            id: 'trading_operacoes',
            label: 'Operações Assistidas',
            icon: FontAwesomeIcons.arrowsLeftRight,
            screenIndex: 79),
        MenuItem(
            id: 'trading_backtest',
            label: 'Backtest',
            icon: FontAwesomeIcons.clockRotateLeft,
            screenIndex: 85),
      ],
    ),
    MenuGroup(
      id: 'sistema',
      label: 'Sistema',
      icon: FontAwesomeIcons.gear,
      items: [
        MenuItem(
            id: 'aplicativo',
            label: 'Aplicativo',
            icon: FontAwesomeIcons.appStore,
            screenIndex: 3),
        MenuItem(
            id: 'cadastro_empresa',
            label: 'Cadastro Empresa',
            icon: FontAwesomeIcons.building,
            screenIndex: 66),
        MenuItem(
            id: 'config_admin',
            label: 'Configurações Admin',
            icon: FontAwesomeIcons.gear,
            screenIndex: 40),
        MenuItem(
            id: 'config_sistema',
            label: 'Config. Sistema',
            icon: FontAwesomeIcons.screwdriverWrench,
            screenIndex: 63),
        MenuItem(
            id: 'editor_telas',
            label: 'Editor de Telas',
            icon: FontAwesomeIcons.tableColumns,
            screenIndex: 52),
        MenuItem(
            id: 'ajuda_telas',
            label: 'Ajuda das Telas',
            icon: FontAwesomeIcons.circleQuestion,
            screenIndex: 84),
        MenuItem(
            id: 'empresas',
            label: 'Empresas',
            icon: FontAwesomeIcons.buildingUser,
            screenIndex: 11),
        MenuItem(
            id: 'permissoes',
            label: 'Permissões',
            icon: FontAwesomeIcons.shieldHalved,
            screenIndex: 59),
        MenuItem(
            id: 'teste_endpoints',
            label: 'Teste de Endpoints',
            icon: FontAwesomeIcons.vials,
            screenIndex: 65),
      ],
    ),
  ];

  static const List<MenuItem> loose = [
    MenuItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: FontAwesomeIcons.chartBar,
        screenIndex: 45),
    MenuItem(
        id: 'mensalidades',
        label: 'Mensalidades',
        icon: FontAwesomeIcons.moneyBill,
        screenIndex: 16),
    MenuItem(
        id: 'parceiros',
        label: 'Parceiros',
        icon: FontAwesomeIcons.handshake,
        screenIndex: 19),
    MenuItem(
        id: 'pedidos',
        label: 'Pedidos',
        icon: FontAwesomeIcons.cartFlatbed,
        screenIndex: 39),
    MenuItem(
        id: 'crm_funil',
        label: 'CRM/Funil',
        icon: FontAwesomeIcons.chartLine,
        screenIndex: 73),
    MenuItem(
        id: 'automacao_fiscal',
        label: 'Automacao Fiscal',
        icon: FontAwesomeIcons.fileCircleCheck,
        screenIndex: 74),
  ];

  static List<MenuItem> get allItems {
    final all = <MenuItem>[];
    for (final g in groups) {
      all.addAll(g.items);
    }
    all.addAll(loose);
    return all;
  }

  static List<MenuItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return allItems.where((m) => m.label.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  static MenuGroup? groupOf(String itemId) {
    for (final g in groups) {
      if (g.items.any((i) => i.id == itemId)) return g;
    }
    return null;
  }
}
