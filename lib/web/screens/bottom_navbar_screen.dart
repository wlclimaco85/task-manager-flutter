import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/custom_colors.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';
import '../../services/alert_caller.dart';
import './aplicativo_screen.dart';
import '../../../auth_screens/login_screen.dart';
import './chamado_grid_screen.dart';
import './alimento_grid_screen.dart';
import './comunicado_componente_screen.dart';
import './dieta_grid_screen.dart';
import './empresa_grid_screen.dart';
import './exame_grid_screen.dart';
import './exercicio_grid_screen.dart';
import './grupo_muscular_grid_screen.dart';
import './medicamento_grid_screen.dart';
import './mensalidade_grid_screen.dart';
import './modalidade_grid_screen.dart';
import './objetivo_grid_screen.dart';
import './parceiro_grid_screen.dart';
import './tipo_parceiro_grid_screen.dart';
import './servico_contratado_grid_screen.dart';
import './modulo_servico_grid_screen.dart';
import './regime_grid_screen.dart';
import './noticias_grid_screen.dart';
import './conta_pagar_grid_screen.dart';
import './dashboard_financeiro_screen.dart';
import './conta_receber_grid_screen.dart';
import './lancamento_financeiro_grid_screen.dart';
import './diretorio_grid_screen.dart';
import './ged_arquivos_screen.dart';
import './forma_pagamento_grid_screen.dart';
import './login_grid_screen.dart';
import './obrigacao_fiscal_grid_screen.dart';
import './personal_grid_screen.dart';
import './plano_grid_screen.dart';
import './product_register_screen.dart';
import './role_grid_screen.dart';
import './role_permissao_screen.dart';
import './setor_grid_screen.dart';
import './suplemento_grid_screen.dart';
import 'documento_screen.dart';
import './calendario_guias_grid_screen.dart';
import './configuracoes_admin_screen.dart';
import './cotacao_frete_grid_screen.dart';
import './dividendo_grid_screen.dart';
import './order_grid_screen.dart';
import './pedido_grid_screen.dart';
import './ticket_grid_screen.dart';
import './alerta_aluno_grid_screen.dart';
import './avaliacao_fisica_grid_screen.dart';
import './academia_grid_screen.dart';
import './conta_bancaria_grid_screen.dart';
import './centro_custo_grid_screen.dart';
import './categoria_financeira_grid_screen.dart';
import './classificacao_grid_screen.dart';
import './dashboard_grid_screen.dart';
import './feriado_grid_screen.dart';
import './treino_grid_screen.dart';
import './system_test_screen.dart';
import './cadastro_empresa_wizard.dart';
import './funcionario_grid_screen.dart';
import './kanban_chamados_screen.dart';
import './tela_editor_screen.dart';
import './produto_grid_screen.dart';
import './unidade_medida_grid_screen.dart';
import './catalago_produto_grid_screen.dart';
import './nfe_finalidade_grid_screen.dart';
import './nfe_serie_grid_screen.dart';
import './nfe_tipo_operacao_grid_screen.dart';
import './nfe_grid_screen.dart';
import './nfe_import_screen.dart';
import './nfe_import_xml_screen.dart';
import './consulta_dfe_screen.dart';
import './manifestacao_destinatario_screen.dart';
import './ponto_web_screen.dart';
import './ponto_solicitacao_screen.dart';
import './ponto_ajuste_screen.dart';
import './configuracoes_sistema_screen.dart';
import './chatMessageListScreen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../features/trading/screens/sinais_screen.dart';
import '../../features/trading/screens/oportunidades_screen.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/screens/trading_config_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../features/trading/screens/carteira_screen.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../../utils/menu_config.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/internal_tab_strip.dart';
import '../../models/open_tab.dart';
import './alvara_grid_screen.dart';
import './fornecedor_grid_screen.dart';
import './nfce/pdv_screen.dart';
import './nfce/config_fiscal_screen.dart';
import '../../windows/screens/reserva_estoque_screen.dart';
import '../../windows/screens/deposito_screen.dart';
import '../../windows/screens/renegociacao_screen.dart';
import '../../windows/screens/devolucao_grid_screen.dart';
import './extrato_importacao_screen.dart';
import './conciliacao_screen.dart';
import './integracoes_financeiras_screen.dart';
import './orcamento_grid_screen.dart';
import './pedido_venda_grid_screen.dart';
import './pedido_compra_grid_screen.dart';
import '../../windows/screens/nfse_screen.dart';
import './cancelamento_cce_screen.dart';
import 'contabil/conta_contabil_grid_screen.dart';
import 'contabil/lancamento_contabil_grid_screen.dart';
import 'contabil/balancete_screen.dart';
import 'contabil/fechamento_periodo_screen.dart';
import 'contabil/ai_dashboard_screen.dart';
import 'contabil/ai_assistente_screen.dart';
import './cobranca_automatica_screen.dart';
import './kanban_pagamentos_screen.dart';
import './aprovacao_pagamentos_screen.dart';

class WebBottomNavBarScreen extends StatefulWidget {
  final int initialIndex;
  const WebBottomNavBarScreen({super.key, this.initialIndex = 31});

  @override
  State<WebBottomNavBarScreen> createState() => _WebBottomNavBarScreenState();
}

class _WebBottomNavBarScreenState extends State<WebBottomNavBarScreen> {
  static const int _maxOpenTabs = 5;

  late int _initialScreenIndex;
  bool _isSidebarCollapsed = false;
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  Timer? _periodicTimer;
  OverlayEntry? notificationOverlay;
  bool _isLoading = true;
  late List<Widget> _screens;

  final List<OpenTab> _openTabs = [];
  int _activeTabIndex = 0;

  int get _selectedIndex =>
      _openTabs.isEmpty ? _initialScreenIndex : _openTabs[_activeTabIndex].screenIndex;

  @override
  void initState() {
    super.initState();
    _initialScreenIndex = widget.initialIndex;
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    await AuthUtility.isUserLoggedIn();
    if (!mounted) return;
    final hasData = AuthUtility.userInfo?.data?.id != null;
    final hasLogin = AuthUtility.userInfo?.login?.id != null;
    if (!hasData && !hasLogin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() {
      _screens = _buildScreensList();
      _isLoading = false;
      _openInitialTab();
    });
    _startPeriodicFetch();
  }

  // ── Gerenciamento de abas internas ───────────────────────────────────────

  MenuItem? _menuItemForScreenIndex(int screenIndex) {
    final all = [...MenuConfig.groups.expand((g) => g.items), ...MenuConfig.loose];
    for (final item in all) {
      if (item.screenIndex == screenIndex) return item;
    }
    return null;
  }

  OpenTab _buildTab(int screenIndex) {
    final menuItem = _menuItemForScreenIndex(screenIndex);
    final widgetIndex = screenIndex.clamp(0, _screens.length - 1);
    return OpenTab(
      id: 'screen_$screenIndex',
      label: menuItem?.label ?? 'Tela $screenIndex',
      icon: menuItem?.icon ?? FontAwesomeIcons.fileLines,
      content: KeyedSubtree(
        key: ValueKey('screen_$screenIndex'),
        child: _screens[widgetIndex],
      ),
      screenIndex: screenIndex,
    );
  }

  void _openInitialTab() {
    if (_openTabs.isEmpty) {
      _openTabs.add(_buildTab(_initialScreenIndex));
      _activeTabIndex = 0;
    }
  }

  void _activateOrOpenTab(MenuItem item) {
    if (item.screenIndex < 0) return;
    final screenIndex = item.screenIndex;

    final existingIndex = _openTabs.indexWhere((t) => t.screenIndex == screenIndex);
    if (existingIndex != -1) {
      setState(() => _activeTabIndex = existingIndex);
      return;
    }

    if (_openTabs.length < _maxOpenTabs) {
      setState(() {
        _openTabs.add(_buildTab(screenIndex));
        _activeTabIndex = _openTabs.length - 1;
      });
      return;
    }

    _showTabLimitDialogAndReplace(screenIndex, item.label);
  }

  Future<void> _showTabLimitDialogAndReplace(int newScreenIndex, String newLabel) async {
    final indicesParaFechar = await showTabLimitDialog(
      context: context,
      tabs: _openTabs,
      newTabLabel: newLabel,
      isCompact: true,
    );
    if (indicesParaFechar == null || indicesParaFechar.isEmpty || !mounted) return;

    setState(() {
      final ordenados = [...indicesParaFechar]..sort((a, b) => b.compareTo(a));
      for (final i in ordenados) {
        _openTabs.removeAt(i);
      }
      _openTabs.add(_buildTab(newScreenIndex));
      _activeTabIndex = _openTabs.length - 1;
    });
  }

  void _closeTab(int index) {
    if (index < 0 || index >= _openTabs.length) return;
    setState(() {
      _openTabs.removeAt(index);
      if (_openTabs.isEmpty) {
        _openInitialTab();
        return;
      }
      if (_activeTabIndex == index) {
        _activeTabIndex = (index - 1).clamp(0, _openTabs.length - 1);
      } else if (_activeTabIndex > index) {
        _activeTabIndex -= 1;
      }
    });
  }

  String get userName {
    final user = AuthUtility.userInfo?.data;
    final login = AuthUtility.userInfo?.login;
    if (user?.firstName != null && user?.lastName != null) {
      return '${user!.firstName!} ${user.lastName!}';
    } else if (user?.email != null) {
      return user!.email!;
    } else if (login?.nome != null) {
      return login!.nome!;
    } else if (login?.email != null) {
      return login!.email!;
    }
    return 'Usuário';
  }

  List<Widget> _buildScreensList() {
    final userInfo = AuthUtility.userInfo?.data;
    final loginInfo = AuthUtility.userInfo?.login;
    final isLoggedIn = (userInfo?.id != null) || (loginInfo?.id != null);
    if (!isLoggedIn) return [const LoginScreen()];
    return [
      WebComunicadoGridComponentesScreen(hasPermission: (p) => true), // 0:  Comunicados
      WebChatListScreen(
          userName: AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 1: Chat
      WebComunicadoGridComponentesScreen(
          hasPermission: (p) => true), // 2:  ComunicadoComp
      WebAplicativoGridScreen(hasPermission: (p) => true), // 3:  Aplicativo
      WebLoginGridScreen(hasPermission: (p) => true), // 4:  Logins
      WebChatListScreen(
          userName:
              AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 5: ChatList
      const WebProductRegisterScreen(), // 6:  placeholder
      const WebProductRegisterScreen(), // 7:  placeholder
      WebRegimeGridScreen(hasPermission: (p) => true), // 8:  Regime
      WebAlimentoGridScreen(hasPermission: (p) => true), // 9:  Alimentos
      WebDietaGridScreen(hasPermission: (p) => true), // 10: Dietas
      WebEmpresaGridScreen(hasPermission: (p) => true), // 11: Empresas
      WebExameGridScreen(hasPermission: (p) => true), // 12: Exames
      WebExercicioGridScreen(hasPermission: (p) => true), // 13: Exercícios
      WebGrupoMuscularGridScreen(
          hasPermission: (p) => true), // 14: GruposMusculares
      WebMedicamentoGridScreen(hasPermission: (p) => true), // 15: Medicamentos
      WebMensalidadeGridScreen(hasPermission: (p) => true), // 16: Mensalidades
      WebModalidadeGridScreen(hasPermission: (p) => true), // 17: Modalidades
      WebObjetivoGridScreen(hasPermission: (p) => true), // 18: Objetivos
      WebParceiroGridScreen(hasPermission: (p) => true), // 19: Parceiros
      WebPersonalGridScreen(hasPermission: (p) => true), // 20: Personais
      WebPlanoGridScreen(hasPermission: (p) => true), // 21: Planos
      WebRoleGridScreen(hasPermission: (p) => true), // 22: Roles
      WebSetorGridScreen(hasPermission: (p) => true), // 23: Setores
      WebSuplementoGridScreen(hasPermission: (p) => true), // 24: Suplementos
      WebContaPagarGridScreen(hasPermission: (p) => true), // 25: ContasPagar
      WebContaReceberGridScreen(
          hasPermission: (p) => true), // 26: ContasReceber
      WebChamadoGridScreen(hasPermission: (p) => true), // 27: Chamados
      WebFormaPagamentoGridScreen(
          hasPermission: (p) => true), // 28: FormasPagamento
      WebDiretorioGridScreen(hasPermission: (p) => true), // 29: Diretorios
      const GedArquivosScreen(), // 30: GED — Arquivos
      WebCalendarScreen(), // 31: Calendario
      WebObrigacaoFiscalGridScreen(
          hasPermission: (p) => true), // 32: ObrigacoesFiscais
      WebLoginGridScreen(hasPermission: (p) => true), // 33: Logins(dup)
      WebCotacaoFreteGridScreen(hasPermission: (p) => true), // 34: CotacaoFrete
      WebCalendarioGuiasGridScreen(
          hasPermission: (p) => true), // 35: CalendarioGuias
      WebTicketGridScreen(hasPermission: (p) => true), // 36: Tickets
      WebDividendoGridScreen(hasPermission: (p) => true), // 37: Dividendos
      WebOrderGridScreen(hasPermission: (p) => true), // 38: Ordens
      WebPedidoGridScreen(hasPermission: (p) => true), // 39: Pedidos
      WebConfiguracoesAdminScreen(
          hasPermission: (p) => true), // 40: ConfigAdmin
      WebAlertaAlunoGridScreen(hasPermission: (p) => true), // 41: AlertaAluno
      WebAvaliacaoFisicaGridScreen(
          hasPermission: (p) => true), // 42: AvaliacaoFisica
      WebContaBancariaGridScreen(
          hasPermission: (p) => true), // 43: ContaBancaria
      WebClassificacaoGridScreen(
          hasPermission: (p) => true), // 44: Classificacao
      const WebDashboardScreen(), // 45: Dashboard
      WebFeriadoGridScreen(hasPermission: (p) => true), // 46: Feriados
      const WebNfeGridScreen(entrada: true), // 47: NFeEntrada
      const WebNfeGridScreen(entrada: false), // 48: NFeSaida
      WebTreinoGridScreen(hasPermission: (p) => true), // 49: Treino
      WebFuncionarioGridScreen(hasPermission: (p) => true), // 50: Funcionarios
      const KanbanChamadosScreen(), // 51: Kanban
      const TelaEditorScreen(), // 52: EditorTelas
      WebProdutoGridScreen(hasPermission: (p) => true), // 53: Produtos
      WebNfeFinalidadeGridScreen(
          hasPermission: (p) => true), // 54: NfeFinalidade
      WebNfeSerieGridScreen(hasPermission: (p) => true), // 55: NfeSerie
      WebNfeTipoOperacaoGridScreen(
          hasPermission: (p) => true), // 56: NfeTipoOperacao
      WebUnidadeMedidaGridScreen(
          hasPermission: (p) => true), // 57: UnidadeMedida
      WebCatalagoProdutoGridScreen(
          hasPermission: (p) => true), // 58: CatalagoProduto
      const RolePermissaoScreen(), // 59: Permissoes
      const WebPontoScreen(), // 60: Ponto
      const WebPontoSolicitacaoScreen(), // 61: SolicitarAjuste
      const WebPontoAjusteScreen(), // 62: AjustePonto
      const ConfiguracoesSistemaScreen(), // 63: ConfigSistema
      WebChatListScreen(
          userName:
              AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 64: Chat
      const SystemTestScreen(), // 65: Teste
      const CadastroEmpresaWizard(), // 66: CadastroEmpresa
      WebTipoParceiroGridScreen(hasPermission: (p) => true), // 67: TipoParceiro
      WebServicoContratadoGridScreen(
          hasPermission: (p) => true), // 68: ServicoContratado
      WebModuloServicoGridScreen(
          hasPermission: (p) => true), // 69: ModuloServico
      WebAlvaraGridScreen(hasPermission: (p) => true), // 70: Alvarás
      const NfeImportScreen(), // 71: NfeImportCSV
      const TradingDashboardScreen(), // 72: Painel Trading
      WebCentroCustoGridScreen(hasPermission: (p) => true), // 73: CentroCusto
      WebCategoriaFinanceiraGridScreen(
          hasPermission: (p) => true), // 74: CategoriasFinanceiras
      const SinaisScreen(), // 75: Sinais de Mercado
      const OportunidadesScreen(), // 76: Oportunidades
      const TradingDashboardScreen(initialTabIndex: 1), // 77: Watchlist
      const TradingDashboardScreen(initialTabIndex: 2), // 78: Alertas de Preço
      const TradingDashboardScreen(
          initialTabIndex: 3), // 79: Operações Assistidas
      const PdvScreen(), // 80: PDV NFC-e
      const ConfigFiscalScreen(), // 81: Config. Fiscal
      const SizedBox.shrink(), // 82
      const SizedBox.shrink(), // 83
      const SizedBox.shrink(), // 84: Ajuda (não disponível)
      BacktestScreen(
          repository: BacktestRepository(ApiLinks.baseUrl,
              headers: TenantContext.jsonHeaders)), // 85: Backtest
      const WebNfeImportXmlScreen(), // 86: NfeImportXml
      WebNoticiasGridScreen(hasPermission: (p) => true), // 87: Noticias
      WebLancamentoFinanceiroGridScreen(
          hasPermission: (p) => true), // 88: LancamentosFinanceiros
      const ExtratoImportacaoScreen(), // 89: ImportarExtrato
      const WebConciliacaoScreen(), // 90: ConciliacaoBancaria
      const WebDashboardFinanceiroScreen(), // 91: DashboardFinanceiro
      const WebIntegracoesFinanceirasScreen(), // 92: IntegracoesFinanceiras
      WebFornecedorGridScreen(hasPermission: (p) => true), // 93: Fornecedores
      const WebOrcamentoGridScreen(), // 94: Orçamentos
      const WebPedidoVendaGridScreen(), // 95: Pedidos de Venda
      const WebPedidoCompraGridScreen(), // 96: Pedidos de Compra
      const ConsultaDfeScreen(), // 97: Consulta DF-e
      const ManifestacaoDestinatarioScreen(), // 98: Manifestação Destinatário
      const NfseScreen(), // 99: NFSe
      const ReservaEstoqueScreen(), // 100: ReservaEstoque
      const DepositoScreen(), // 101: Multi-depósito
      const SizedBox.shrink(), // 102: Rateio Financeiro (web)
      const SizedBox.shrink(), // 103: Aprovação de Pagamentos (web)
      const SizedBox.shrink(), // 104: Baixa Automática (web)
      const SizedBox.shrink(), // 105: Cobrança (web)
      const RenegociacaoScreen(), // 106: Renegociação de Títulos
      const WindowsDevolucaoGridScreen(), // 107: Devoluções
      const SizedBox.shrink(), // 108
      const SizedBox.shrink(), // 109
      const SizedBox.shrink(), // 110
      const CancelamentoCceScreen(), // 111: Cancelamento e CC-e
      const SizedBox.shrink(), // 112: RegraFiscal (web vago)
      WebContaContabilGridScreen(
          hasPermission: (p) => true), // 113: Plano de Contas
      WebLancamentoContabilGridScreen(
          hasPermission: (p) => true), // 114: Lançamentos
      const WebBalanceteScreen(), // 115: Balancete / Balanço
      const WebFechamentoPeriodoScreen(), // 116: Fechamento de Período
      const WebAiDashboardScreen(), // 117: Dashboard IA
      const WebAiAssistenteScreen(), // 118: Assistente IA
      const TradingConfigScreen(), // 119: Configuracao da Corretora
      const CarteiraScreen(), // 132: Minha Carteira
      const CobrancaAutomaticaScreen(), // 133: Cobrança Automática
      const KanbanPagamentosScreen(), // 134: Kanban de Pagamentos
      const WebAprovacaoPagamentosScreen(), // 135: Aprovação de Pagamentos
      WebAcademiaGridScreen(hasPermission: (p) => true), // 124: Academia
    ];
  }

  void _startPeriodicFetch() {
    _periodicTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => fetchAlerts());
  }

  Future<void> fetchAlerts() async {
    try {
      final List<Alert> alertData =
          await AlertCaller().fetchNotificacoes(context);
      if (!mounted) return;
      if (alertData.isNotEmpty) {
        setState(() {
          notifications = alertData;
          unreadAlerts = notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void deleteNotification(int id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
  }

  void deleteAllNotifications() {
    setState(() {
      notifications.clear();
      unreadAlerts = 0;
    });
  }

  void closeNotificationDropdown() {
    notificationOverlay?.remove();
    notificationOverlay = null;
  }

  void showNotificationDropdown(BuildContext context, Offset position) {
    if (notificationOverlay != null) {
      closeNotificationDropdown();
      return;
    }
    final overlay = Overlay.of(context);
    notificationOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        top: position.dy + 40,
        left: _isSidebarCollapsed ? 70 : 260,
        child: Material(
          elevation: 4,
          child: Container(
            width: 300,
            height: 400,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CustomColors().getLightGreenBackground(),
              border: Border.all(
                  color: CustomColors().getDarkGreenBorder(), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notificações',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CustomColors().getTextColor())),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: CustomColors().getCancelButtonColor()),
                      onPressed: closeNotificationDropdown,
                    ),
                  ],
                ),
                const Divider(color: Colors.green, thickness: 1),
                ListTile(
                  dense: true,
                  title: Text('Deletar Tudo',
                      style: TextStyle(
                          fontSize: 14,
                          color: CustomColors().getCancelButtonColor())),
                  trailing: Icon(Icons.delete_forever,
                      color: CustomColors().getCancelButtonColor(), size: 20),
                  onTap: deleteAllNotifications,
                ),
                const Divider(color: Colors.green, thickness: 1),
                Expanded(
                  child: notifications.isNotEmpty
                      ? ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (_, i) {
                            final n = notifications[i];
                            final dt = DateTime.parse(n.data!);
                            final fmt =
                                '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            return ListTile(
                              title: Text(n.texto,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          CustomColors().getButtonTextColor())),
                              subtitle: Text(fmt,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          CustomColors().getButtonTextColor())),
                              trailing: IconButton(
                                icon: Icon(Icons.delete,
                                    color:
                                        CustomColors().getCancelButtonColor(),
                                    size: 20),
                                onPressed: () => deleteNotification(n.id),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text('Sem notificações',
                              style: TextStyle(
                                  color: CustomColors().getButtonTextColor()))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(notificationOverlay!);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Deseja realmente sair?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomColors().getTextColor())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Não',
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
          TextButton(
            onPressed: () {
              AuthUtility.clearUserInfo();
              AuthUtility.setUserInfo(
                  LoginModel(data: null, token: '', status: ''));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const WebBottomNavBarScreen()),
                (route) => false,
              );
            },
            child: Text('Sim',
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    notificationOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Row(
        children: [
          // Sidebar com submenus, busca e favoritos
          AppSidebar(
            selectedIndex: _selectedIndex,
            onSelect: _activateOrOpenTab,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () =>
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            unreadAlerts: unreadAlerts,
            onNotificationTap: () {
              final box = context.findRenderObject() as RenderBox;
              showNotificationDropdown(context, box.localToGlobal(Offset.zero));
            },
            onLogout: _handleLogout,
            userName: userName,
            userEmail: AuthUtility.userInfo?.data?.codDadosPessoal?.email ??
                AuthUtility.userInfo?.login?.email ??
                '',
          ),
          // Conteúdo principal: faixa de abas internas + IndexedStack preservando estado
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  InternalTabStrip(
                    tabs: _openTabs,
                    activeIndex: _activeTabIndex,
                    onActivate: (i) => setState(() => _activeTabIndex = i),
                    onClose: _closeTab,
                    isCompact: true,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _activeTabIndex,
                      children: _openTabs.map((t) => t.content).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List showBase64Image(dynamic base64String) {
  if (base64String != null && base64String.toString().trim().isNotEmpty) {
    final image = 'data:image/png;base64,$base64String';
    final data = Uri.parse(image).data;
    return data!.contentAsBytes();
  }
  return Uint8List(0);
}
