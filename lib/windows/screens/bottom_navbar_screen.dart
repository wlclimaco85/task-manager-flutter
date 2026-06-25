import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/custom_colors.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';
import '../../services/alert_caller.dart';
import '../../../windows/screens/alimento_grid_screen.dart';
import '../../../windows/screens/aplicativo_screen.dart';
import '../../../auth_screens/login_screen.dart';
import '../../../windows/screens/chamado_grid_screen.dart';
import '../../../windows/screens/chatMenssageScreen.dart';
import '../../../windows/screens/chatMessageListScreen.dart';
import '../../../windows/screens/comunicado_componente_screen.dart';
import '../../../windows/screens/integracoes_financeiras_screen.dart';
import '../../../windows/screens/conta_pagar_grid_screen.dart';
import '../../../windows/screens/conta_receber_grid_screen.dart';
import '../../../windows/screens/dashboard_financeiro_screen.dart';
import '../../../windows/screens/lancamento_financeiro_grid_screen.dart';
import '../../../windows/screens/dieta_grid_screen.dart';
import '../../../windows/screens/diretorio_grid_screen.dart';
import '../../../windows/screens/empresa_grid_screen.dart';
import '../../../windows/screens/exame_grid_screen.dart';
import '../../../windows/screens/exercicio_grid_screen.dart';
import '../../windows/screens/ged_arquivos_screen.dart';
import '../../../windows/screens/forma_pagamento_grid_screen.dart';
import '../../../windows/screens/grupo_muscular_grid_screen.dart';
import '../../../windows/screens/login_grid_screen.dart';
import '../../../windows/screens/medicamento_grid_screen.dart';
import '../../../windows/screens/mensalidade_grid_screen.dart';
import '../../../windows/screens/modalidade_grid_screen.dart';
import '../../../windows/screens/objetivo_grid_screen.dart';
import '../../../windows/screens/obrigacao_fiscal_grid_screen.dart';
import '../../../windows/screens/parceiro_grid_screen.dart';
import '../../../windows/screens/personal_grid_screen.dart';
import '../../../windows/screens/plano_grid_screen.dart';
import '../../../windows/screens/product_register_screen.dart';
import '../../../windows/screens/regime_grid_screen.dart';
import '../../../windows/screens/role_grid_screen.dart';
import '../../../windows/screens/setor_grid_screen.dart';
import '../../../windows/screens/suplemento_grid_screen.dart';
import 'documento_screen.dart';
import '../../../windows/screens/calendario_guias_grid_screen.dart';
import '../../../windows/screens/extrato_importacao_screen.dart';
import '../../../windows/screens/conciliacao_screen.dart';
import '../../../windows/screens/configuracoes_admin_screen.dart';
import '../../../windows/screens/cotacao_frete_grid_screen.dart';
import '../../../windows/screens/dividendo_grid_screen.dart';
import '../../../windows/screens/order_grid_screen.dart';
import '../../../windows/screens/pedido_grid_screen.dart';
import '../../../windows/screens/ticket_grid_screen.dart';
import '../../../windows/screens/alerta_aluno_grid_screen.dart';
import '../../../windows/screens/avaliacao_fisica_grid_screen.dart';
import '../../../windows/screens/academia_grid_screen.dart';
import '../../../windows/screens/conta_bancaria_grid_screen.dart';
import '../../../windows/screens/centro_custo_grid_screen.dart';
import '../../../windows/screens/categoria_financeira_grid_screen.dart';
import '../../../windows/screens/classificacao_grid_screen.dart';
import '../../../windows/screens/feriado_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_entrada_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_saida_grid_screen.dart';
import '../../../windows/screens/produto_grid_screen.dart';
import '../../../windows/screens/treino_grid_screen.dart';
import '../../../windows/screens/funcionario_grid_screen.dart';
import '../../windows/screens/kanban_chamados_screen.dart';
import '../../windows/screens/tela_editor_screen.dart';
import '../../mobile/screens/dashboard_screen.dart';
import '../../../features/trading/trading_dashboard_screen.dart';
import '../../../features/trading/screens/sinais_screen.dart';
import '../../../features/trading/screens/oportunidades_screen.dart';
import '../../../features/trading/screens/backtest_screen.dart';
import '../../../features/trading/screens/trading_config_screen.dart';
import '../../../features/trading/services/backtest_repository.dart';
import '../../../features/trading/screens/carteira_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/menu_config.dart';
import '../../../widgets/app_sidebar.dart';
import '../../../widgets/internal_tab_strip.dart';
import '../../../models/open_tab.dart';
// Telas web reutilizadas no Windows
import '../../windows/screens/nfe_finalidade_grid_screen.dart';
import '../../windows/screens/nfe_serie_grid_screen.dart';
import '../../windows/screens/nfe_tipo_operacao_grid_screen.dart';
import '../../windows/screens/unidade_medida_grid_screen.dart';
import '../../windows/screens/catalago_produto_grid_screen.dart';
import '../../windows/screens/role_permissao_screen.dart';
import '../../windows/screens/tipo_parceiro_grid_screen.dart';
import '../../windows/screens/servico_contratado_grid_screen.dart';
import '../../windows/screens/modulo_servico_grid_screen.dart';
import '../../windows/screens/ponto_web_screen.dart';
import '../../windows/screens/ponto_solicitacao_screen.dart';
import '../../windows/screens/ponto_ajuste_screen.dart';
import '../../windows/screens/configuracoes_sistema_screen.dart';
import '../../windows/screens/system_test_screen.dart';
import '../../windows/screens/cadastro_empresa_wizard.dart';
import '../../windows/screens/alvara_grid_screen.dart';
import '../../windows/screens/fornecedor_grid_screen.dart';
import '../../windows/screens/nfe_import_screen.dart';
import '../../windows/screens/nfe_import_xml_screen.dart';
import '../../windows/screens/consulta_dfe_screen.dart';
import '../../windows/screens/manifestacao_destinatario_screen.dart';
import '../../windows/screens/nfce/pdv_screen.dart';
import '../../windows/screens/nfce/config_fiscal_screen.dart';
import '../../windows/screens/orcamento_grid_screen.dart';
import '../../windows/screens/pedido_venda_grid_screen.dart';
import '../../windows/screens/pedido_compra_grid_screen.dart';
import '../../windows/screens/nfse_screen.dart';
import '../../windows/screens/reserva_estoque_screen.dart';
import '../../windows/screens/deposito_screen.dart';
import '../../windows/screens/rateio_financeiro_screen.dart';
import '../../windows/screens/aprovacao_pagamento_screen.dart';
import '../../windows/screens/baixa_automatica_screen.dart';
import '../../windows/screens/cobranca_screen.dart';
import '../../windows/screens/renegociacao_screen.dart';
import '../../windows/screens/dre_screen.dart';
import '../../windows/screens/tabela_preco_screen.dart';
import '../../windows/screens/aprovacao_compra_screen.dart';
import '../../windows/screens/devolucao_grid_screen.dart';
import '../../windows/screens/cancelamento_cce_screen.dart';
import '../../windows/screens/regra_fiscal_screen.dart';
import '../../web/screens/contabil/conta_contabil_grid_screen.dart';
import '../../web/screens/contabil/lancamento_contabil_grid_screen.dart';
import '../../web/screens/contabil/balancete_screen.dart';
import '../../web/screens/contabil/fechamento_periodo_screen.dart';
import '../../web/screens/contabil/ai_dashboard_screen.dart';
import '../../web/screens/contabil/ai_assistente_screen.dart';
import '../../web/screens/cobranca_automatica_screen.dart';
import '../../web/screens/kanban_pagamentos_screen.dart';
import '../../web/screens/aprovacao_pagamentos_screen.dart';

class WindowsBottomNavBarScreen extends StatefulWidget {
  const WindowsBottomNavBarScreen({super.key});

  @override
  State<WindowsBottomNavBarScreen> createState() =>
      _WindowsBottomNavBarScreenState();
}

class _WindowsBottomNavBarScreenState extends State<WindowsBottomNavBarScreen> {
  static const int _initialScreenIndex = 31; // Calendário como tela inicial
  static const int _maxOpenTabs = 5;

  bool _isSidebarCollapsed = false;
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  bool _isLoading = true;
  late List<Widget> _screens;

  final List<OpenTab> _openTabs = [];
  int _activeTabIndex = 0;

  int get _selectedIndex => _openTabs.isEmpty
      ? _initialScreenIndex
      : _openTabs[_activeTabIndex].screenIndex;

  @override
  void initState() {
    super.initState();
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    await AuthUtility.isUserLoggedIn();
    if (!mounted) return;
    final userInfo = AuthUtility.userInfo?.data;
    if (userInfo == null || userInfo.id == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() {
      _screens = _buildScreens(userInfo);
      _isLoading = false;
      _openInitialTab();
    });
    _startPeriodicFetch();
  }

  // ── Gerenciamento de abas internas ───────────────────────────────────────

  MenuItem? _menuItemForScreenIndex(int screenIndex) {
    final all = [
      ...MenuConfig.groups.expand((g) => g.items),
      ...MenuConfig.loose
    ];
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

    final existingIndex =
        _openTabs.indexWhere((t) => t.screenIndex == screenIndex);
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

  Future<void> _showTabLimitDialogAndReplace(
      int newScreenIndex, String newLabel) async {
    final indicesParaFechar = await showTabLimitDialog(
      context: context,
      tabs: _openTabs,
      newTabLabel: newLabel,
      isCompact: false,
    );
    if (indicesParaFechar == null || indicesParaFechar.isEmpty || !mounted)
      return;

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
        // Foca a aba à esquerda; se não houver, a próxima à direita.
        _activeTabIndex = (index - 1).clamp(0, _openTabs.length - 1);
      } else if (_activeTabIndex > index) {
        _activeTabIndex -= 1;
      }
    });
  }

  List<Widget> _buildScreens(dynamic userInfo) => [
        WindowsComunicadoGridComponentesScreen(
            hasPermission: (permission) => true),
        const WindowsChatMessageScreen(
          sector: 'Financeiro',
          userName: 'Usuário',
          chatId: '0',
        ),
        WindowsComunicadoGridComponentesScreen(
            hasPermission: (permission) => true),
        WindowsAplicativoGridScreen(hasPermission: (permission) => true),
        WindowsLoginGridScreen(hasPermission: (permission) => true),
        WindowsChatListScreen(userName: userInfo.email ?? 'Usuário'),
        const WindowsProductRegisterScreen(),
        const WindowsProductRegisterScreen(),
        WindowsRegimeGridScreen(hasPermission: (perm) => true),
        WindowsAlimentoGridScreen(hasPermission: (perm) => true),
        WindowsDietaGridScreen(hasPermission: (perm) => true),
        WindowsEmpresaGridScreen(hasPermission: (perm) => true),
        WindowsExameGridScreen(hasPermission: (perm) => true),
        WindowsExercicioGridScreen(hasPermission: (perm) => true),
        WindowsGrupoMuscularGridScreen(hasPermission: (perm) => true),
        WindowsMedicamentoGridScreen(hasPermission: (perm) => true),
        WindowsMensalidadeGridScreen(hasPermission: (perm) => true),
        WindowsModalidadeGridScreen(hasPermission: (perm) => true),
        WindowsObjetivoGridScreen(hasPermission: (perm) => true),
        WindowsParceiroGridScreen(hasPermission: (perm) => true),
        WindowsPersonalGridScreen(hasPermission: (perm) => true),
        WindowsPlanoGridScreen(hasPermission: (perm) => true),
        WindowsRoleGridScreen(hasPermission: (perm) => true),
        WindowsSetorGridScreen(hasPermission: (perm) => true),
        WindowsSuplementoGridScreen(hasPermission: (perm) => true),
        WindowsContaPagarGridScreen(hasPermission: (perm) => true),
        WindowsContaReceberGridScreen(hasPermission: (perm) => true),
        WindowsChamadoGridScreen(hasPermission: (perm) => true),
        WindowsFormaPagamentoGridScreen(hasPermission: (perm) => true),
        WindowsDiretorioGridScreen(hasPermission: (perm) => true),
        GedArquivosScreen(), // 30: GED
        const WindowsCalendarScreen(),
        WindowsObrigacaoFiscalGridScreen(hasPermission: (perm) => true),
        WindowsLoginGridScreen(hasPermission: (perm) => true),
        // Novas telas
        WindowsCotacaoFreteGridScreen(hasPermission: (perm) => true),
        WindowsCalendarioGuiasGridScreen(hasPermission: (perm) => true),
        WindowsTicketGridScreen(hasPermission: (perm) => true),
        WindowsDividendoGridScreen(hasPermission: (perm) => true),
        WindowsOrderGridScreen(hasPermission: (perm) => true),
        WindowsPedidoGridScreen(hasPermission: (perm) => true),
        WindowsConfiguracoesAdminScreen(hasPermission: (perm) => true),
        WindowsAlertaAlunoGridScreen(hasPermission: (perm) => true),
        WindowsAvaliacaoFisicaGridScreen(hasPermission: (perm) => true),
        WindowsContaBancariaGridScreen(hasPermission: (perm) => true),
        WindowsClassificacaoGridScreen(hasPermission: (perm) => true),
        const DashboardPage(),
        WindowsFeriadoGridScreen(hasPermission: (perm) => true),
        WindowsNotaFiscalEntradaGridScreen(hasPermission: (perm) => true),
        WindowsNotaFiscalSaidaGridScreen(hasPermission: (perm) => true),
        WindowsTreinoGridScreen(hasPermission: (perm) => true),
        WindowsFuncionarioGridScreen(hasPermission: (perm) => true),
        const KanbanChamadosScreen(),
        const TelaEditorScreen(),
        WindowsProdutoGridScreen(hasPermission: (perm) => true),
        // Telas adicionais (índices 54+)
        WindowsNfeFinalidadeGridScreen(hasPermission: (perm) => true), // 54
        WindowsNfeSerieGridScreen(hasPermission: (perm) => true), // 55
        WindowsNfeTipoOperacaoGridScreen(hasPermission: (perm) => true), // 56
        WindowsUnidadeMedidaGridScreen(hasPermission: (perm) => true), // 57
        WindowsCatalagoProdutoGridScreen(hasPermission: (perm) => true), // 58
        const RolePermissaoScreen(), // 59
        const WindowsPontoScreen(), // 60
        const WindowsPontoSolicitacaoScreen(), // 61
        const WindowsPontoAjusteScreen(), // 62
        const ConfiguracoesSistemaScreen(), // 63
        WindowsChatListScreen(
            userName: AuthUtility.userInfo?.data?.email ?? 'Usuário'), // 64
        const SystemTestScreen(), // 65
        const CadastroEmpresaWizard(), // 66
        WindowsTipoParceiroGridScreen(hasPermission: (perm) => true), // 67
        WindowsServicoContratadoGridScreen(hasPermission: (perm) => true), // 68
        WindowsModuloServicoGridScreen(hasPermission: (perm) => true), // 69
        WindowsAlvaraGridScreen(hasPermission: (perm) => true), // 70
        const NfeImportScreen(), // 71: NfeImportCSV
        const TradingDashboardScreen(), // 72: Painel Trading
        WindowsCentroCustoGridScreen(
            hasPermission: (perm) => true), // 73: CentroCusto
        WindowsCategoriaFinanceiraGridScreen(
            hasPermission: (perm) => true), // 74: CategoriasFinanceiras
        const SinaisScreen(), // 75: Sinais de Mercado
        const OportunidadesScreen(), // 76: Oportunidades
        const TradingDashboardScreen(initialTabIndex: 1), // 77: Watchlist
        const TradingDashboardScreen(
            initialTabIndex: 2), // 78: Alertas de Preço
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
        const WindowsNfeImportXmlScreen(), // 86: NfeImportXml
        const SizedBox.shrink(), // 87: (vago)
        WindowsLancamentoFinanceiroGridScreen(
            hasPermission: (perm) => true), // 88: LancamentosFinanceiros
        const ExtratoImportacaoScreen(), // 89: ImportarExtrato
        const ConciliacaoScreen(), // 90: ConciliacaoBancaria
        const WindowsDashboardFinanceiroScreen(), // 91: DashboardFinanceiro
        const IntegracoesFinanceirasScreen(), // 92: IntegracoesFinanceiras
        WindowsFornecedorGridScreen(
            hasPermission: (perm) => true), // 93: Fornecedores
        const WindowsOrcamentoGridScreen(), // 94: Orçamentos
        const WindowsPedidoVendaGridScreen(), // 95: Pedidos de Venda
        const WindowsPedidoCompraGridScreen(), // 96: Pedidos de Compra
        const ConsultaDfeScreen(), // 97: Consulta DF-e
        const ManifestacaoDestinatarioScreen(), // 98: Manifestação Destinatário
        const NfseScreen(), // 99: NFSe
        const ReservaEstoqueScreen(), // 100: ReservaEstoque
        const DepositoScreen(), // 101: Multi-depósito
        const RateioFinanceiroScreen(), // 102: Rateio Financeiro
        const AprovacaoPagamentoScreen(), // 103: Aprovação de Pagamentos
        const BaixaAutomaticaScreen(), // 104: Baixa Automática de Recebíveis
        const CobrancaScreen(), // 105: Inadimplência e Cobrança
        const RenegociacaoScreen(), // 106: Renegociação de Títulos
        const DreScreen(), // 107: DRE Gerencial
        TabelaPrecoScreen(
            hasPermission: (perm) => true), // 108: Tabela de Preços e Descontos
        const AprovacaoCompraScreen(), // 109: Aprovação de Compras
        const WindowsDevolucaoGridScreen(), // 110: Devoluções
        const CancelamentoCceScreen(), // 111: Cancelamento e CC-e
        RegraFiscalScreen(hasPermission: (perm) => true), // 112: Regras Fiscais
        WebContaContabilGridScreen(
            hasPermission: (perm) => true), // 113: Plano de Contas
        WebLancamentoContabilGridScreen(
            hasPermission: (perm) => true), // 114: Lançamentos
        const WebBalanceteScreen(), // 115: Balancete / Balanço
        const WebFechamentoPeriodoScreen(), // 116: Fechamento de Período
        const WebAiDashboardScreen(), // 117: Dashboard IA
        const WebAiAssistenteScreen(), // 118: Assistente IA
        const TradingConfigScreen(), // 119: Configuracao da Corretora
        const CarteiraScreen(), // 120: Minha Carteira
        const CobrancaAutomaticaScreen(), // 121: Cobrança Automática
        const KanbanPagamentosScreen(), // 122: Kanban de Pagamentos
        const WebAprovacaoPagamentosScreen(), // 123: Aprovação de Pagamentos
        WindowsAcademiaGridScreen(
            hasPermission: (perm) => true), // 124: Academia
      ];

  String get userName {
    final user = AuthUtility.userInfo?.data;
    if (user?.firstName != null && user?.lastName != null) {
      return '${user!.firstName!} ${user.lastName!}';
    } else if (user?.email != null) {
      return user!.email!;
    }
    return 'Usuário';
  }

  void _startPeriodicFetch() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) fetchAlerts();
    });
  }

  Future<void> fetchAlerts() async {
    try {
      final List<Alert> alertData =
          await AlertCaller().fetchNotificacoes(context);
      if (alertData.isNotEmpty && mounted) {
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
      builder: (context) => Positioned(
        top: position.dy + 40,
        left: _isSidebarCollapsed ? 70 : 250,
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
                    Text("Notificações",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: CustomColors().getTextColor())),
                    IconButton(
                        icon: Icon(Icons.close,
                            color: CustomColors().getCancelButtonColor()),
                        onPressed: closeNotificationDropdown),
                  ],
                ),
                const Divider(color: Colors.green, thickness: 1),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text("Deletar Tudo",
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
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            final dt = DateTime.parse(n.data!);
                            final fmt =
                                "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
                          child: Text("Sem notificações",
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
      builder: (context) => AlertDialog(
        title: Text("Deseja realmente sair?",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomColors().getTextColor())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Não",
                  style: TextStyle(color: CustomColors().getTextColor()))),
          TextButton(
            onPressed: () {
              AuthUtility.clearUserInfo();
              AuthUtility.setUserInfo(
                  LoginModel(data: null, token: '', status: ''));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const WindowsBottomNavBarScreen()),
                (route) => false,
              );
            },
            child: Text("Sim",
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
          // Sidebar — novo com submenus, busca e favoritos
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
            userEmail: AuthUtility.userInfo?.data?.codDadosPessoal?.email ?? '',
          ),
          // Main Content: faixa de abas internas + IndexedStack preservando estado
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
                    isCompact: false,
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

class SidebarItem {
  final IconData icon;
  final String label;
  SidebarItem({required this.icon, required this.label});
}

Uint8List showBase64Image(base64String) {
  if (base64String != null && base64String.toString().trim().isNotEmpty) {
    final image = "data:image/png;base64,$base64String";
    final data = Uri.parse(image).data;
    return data!.contentAsBytes();
  }
  return Uint8List(0);
}
