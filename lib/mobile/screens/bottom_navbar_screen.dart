import 'dart:async';

import 'package:flutter/material.dart';

import 'package:task_manager_flutter/models/alert_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/services/alert_caller.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart' show CustomAction;
import '../../windows/screens/comunicado_detalhe_screen.dart';
import '../../windows/screens/fechar_chamado_dialog.dart';
import 'sem_acesso_screen.dart';
import '../../auth_screens/login_screen.dart';
import 'chatMessageListScreen.dart';
import 'dashboard_screen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/tenant_context.dart';
import '../../web/screens/nfce/pdv_screen.dart';
import '../../web/screens/nfce/config_fiscal_screen.dart';
import 'documento_screen.dart';
import 'meu_perfil_screen.dart';
import 'ponto_screen.dart';
import '../../widgets/crm/crm_pipeline_screen.dart';
import '../../widgets/fiscal/fiscal_automation_screen.dart';
import 'mensalidade_screen.dart';
import 'conta_pagar_grid_screen.dart';
import 'conta_receber_grid_screen.dart';
import 'conta_bancaria_grid_screen.dart';
import 'parceiro_grid_screen.dart';
import '../../windows/screens/extrato_importacao_screen.dart';
import '../../web/screens/cobranca_automatica_screen.dart';
import '../../widgets/user_banners.dart';
import '../../widgets/dashboard_area/placeholder/dashboard_atendimento_placeholder_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int selectedIndex = 0;

  List<Alert> _notifications = [];
  int _unreadCount = 0;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _alertTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    try {
      final data = await AlertCaller().fetchNotificacoes(context);
      if (mounted) {
        setState(() {
          _notifications = data;
          _unreadCount = data.length;
        });
      }
    } catch (_) {}
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificacoes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _notifications.clear();
                          _unreadCount = 0;
                        });
                        setLocal(() {});
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Limpar tudo'),
                      style: TextButton.styleFrom(
                          foregroundColor: GridColors.error),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sem notificacoes',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final dt = DateTime.tryParse(n.data ?? '');
                        final fmt = dt != null
                            ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '';
                        return ListTile(
                          leading: const Icon(Icons.notifications_outlined,
                              color: GridColors.primary),
                          title: Text(n.texto,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: fmt.isNotEmpty ? Text(fmt) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _notifications.removeWhere((x) => x.id == n.id);
                                _unreadCount = _notifications.length;
                              });
                              setLocal(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Retorna as informacoes do slot dinamico: tela, icone e label.
  /// Retorna null quando nenhum modulo prioritario esta disponivel.
  ({AppScreen screen, IconData icon, String label})? _dynamicSlotInfo(
      SecurityMatrix sec) {
    if (sec.canView(AppScreen.pedidos)) {
      return (
        screen: AppScreen.pedidos,
        icon: Icons.shopping_cart_outlined,
        label: 'Pedidos',
      );
    }
    if (sec.canView(AppScreen.nfeSaida)) {
      return (
        screen: AppScreen.nfeSaida,
        icon: Icons.receipt_long,
        label: 'NFS-e',
      );
    }
    if (sec.canView(AppScreen.contasPagar)) {
      return (
        screen: AppScreen.contasPagar,
        icon: Icons.payments,
        label: 'Financeiro',
      );
    }
    if (sec.canView(AppScreen.ponto)) {
      return (
        screen: AppScreen.ponto,
        icon: Icons.access_time,
        label: 'Ponto',
      );
    }
    return null;
  }

  /// Constroi a tela inline para o slot dinamico conforme o modulo detectado.
  Widget _buildDynamicSlotScreen(
      AppScreen screen, SecurityMatrix sec) {
    switch (screen) {
      case AppScreen.contasPagar:
        return ContaPagarGridScreen(
          hasPermission: (action) =>
              _hasPermissionFor(sec, AppScreen.contasPagar, action),
        );
      case AppScreen.ponto:
        return const PontoScreen();
      default:
        // pedidos, nfeSaida e demais: grade dinamica
        final telaNome = screen == AppScreen.pedidos ? 'pedido' : 'nfe';
        return DynamicGridDynamicScreen(
          key: ValueKey('mobile_dynamic_inline_$telaNome'),
          telaNome: telaNome,
          hasPermission: (action) => _hasPermissionFor(sec, screen, action),
          storageKey: 'mobile_dynamic_$telaNome',
          showAppBar: false,
        );
    }
  }

  List<Widget> _buildScreens(SecurityMatrix sec) {
    final dynamic = _dynamicSlotInfo(sec);
    return [
      // Slot 0 — Inicio (Calendario)
      const CalendarScreen(),
      // Slot 1 — Chat
      AuthUtility.userInfo?.login?.email != null
          ? ChatListScreen(userName: AuthUtility.userInfo?.login?.email ?? '')
          : const ChatListScreen(userName: 'Usuario'),
      // Slot 2 — Comunicados
      _comunicadoGridInline(sec: sec),
      // Slot 3 — Slot dinamico (quando disponivel) ou placeholder
      if (dynamic != null) _buildDynamicSlotScreen(dynamic.screen, sec),
      // Slot 4 (ou 3 sem slot dinamico) — Mais (container vazio)
      Container(),
    ];
  }

  Widget _gedDynamicGrid(SecurityMatrix sec) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_dynamic_inline_ged_arquivo'),
      telaNome: 'arquivo',
      hasPermission: (action) => _hasPermissionFor(sec, AppScreen.ged, action),
      storageKey: 'mobile_dynamic_ged_arquivo',
      fetchEndpointOverride: ApiLinks.allArquivos,
      createEndpointOverride: ApiLinks.createArquivo,
      updateEndpointOverride: ApiLinks.updateArquivo(':id'),
      deleteEndpointOverride: ApiLinks.deleteArquivo(':id'),
    );
  }

  /// Tela de Comunicados mobile: apenas o botao "Visualizar comunicado" (customAction).
  /// hasPermission retorna false para tudo — bloqueia todos os botoes automaticos
  /// (server actions, detailScreenBuilder). Os customActions nao sao afetados.
  Widget _comunicadoGridInline({required SecurityMatrix sec}) {
    return Scaffold(
      appBar: const SimpleAppBar(title: 'Comunicados', icon: Icons.campaign),
      body: DynamicGridDynamicScreen(
        key: const ValueKey('mobile_dynamic_inline_comunicado'),
        telaNome: 'comunicado',
        hasPermission: (action) => false,
        storageKey: 'mobile_dynamic_comunicado',
        showAppBar: false,
        customActions: _comunicadoActionsBuilder,
      ),
    );
  }

  /// Tela de Chamados mobile: "Visualizar", "Fechar" e "Reabrir" — sem botoes automaticos.
  /// hasPermission retorna false para tudo exceto insert/create — bloqueia server actions
  /// e detailScreenBuilder. Os customActions nao sao afetados pelo hasPermission.
  Widget _chamadoGridInline({required SecurityMatrix sec}) {
    return Scaffold(
      appBar:
          const SimpleAppBar(title: 'Solicitacoes', icon: Icons.support_agent),
      body: DynamicGridDynamicScreen(
        key: const ValueKey('mobile_dynamic_inline_chamado'),
        telaNome: 'chamado',
        hasPermission: (action) {
          final lower = action.toLowerCase();
          // Permite criar chamados no mobile
          if (lower == 'insert' || lower == 'create') {
            return _hasPermissionFor(sec, AppScreen.chamados, action);
          }
          // Bloqueia todos os outros botoes automaticos — acoes via customActions
          return false;
        },
        storageKey: 'mobile_dynamic_chamado',
        showAppBar: false,
        customActions: () => [
          CustomAction(
            icon: Icons.open_in_new_outlined,
            label: 'Visualizar chamado',
            onPressed: (ctx, item) => _mostrarDetalheChamado(ctx, item),
            isVisible: (_) => true,
          ),
          CustomAction(
            icon: Icons.task_alt_outlined,
            label: 'Fechar chamado',
            onPressed: (ctx, item) {
              final id = item['id'];
              if (id == null) return;
              final chamadoId =
                  id is int ? id : int.tryParse(id.toString()) ?? 0;
              if (chamadoId == 0) return;
              showDialog(
                context: ctx,
                builder: (_) => FecharChamadoDialog(chamadoId: chamadoId),
              );
            },
            isVisible: (item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status != 'fechado' &&
                  status != 'cancelado' &&
                  status != '3' &&
                  status != '4';
            },
          ),
          CustomAction(
            icon: Icons.replay_outlined,
            label: 'Reabrir chamado',
            onPressed: (ctx, item) => _mostrarReabrirChamadoDialog(ctx, item),
            isVisible: (item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status == 'fechado' ||
                  status == 'cancelado' ||
                  status == '3' ||
                  status == '4';
            },
          ),
        ],
      ),
    );
  }

  /// Exibe um dialog para digitar o motivo e reabrir o chamado.
  void _mostrarReabrirChamadoDialog(
      BuildContext context, Map<String, dynamic> item) {
    final id = item['id'];
    if (id == null) return;
    final chamadoId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    if (chamadoId == 0) return;
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir chamado'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo da reabertura',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final url =
                    '${ApiLinks.baseUrl}/api/chamados/$chamadoId/reabrir';
                await TenantContext.post(url, {'motivo': motivoCtrl.text});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: GridColors.success,
                      content: Text('Chamado reaberto com sucesso'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: GridColors.error,
                      content: Text('Erro ao reabrir chamado: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Reabrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalheChamado(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: GridColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              item['titulo']?.toString() ?? 'Chamado',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _detalheRow('Descricao', item['descricao']),
            _detalheRow('Status', item['status']),
            _detalheRow('Prioridade', item['prioridade']),
            _detalheRow('Setor', item['setor']?['nome'] ?? item['setor']),
            _detalheRow(
                'Abertura', item['dhCreatedAt'] ?? item['dataAbertura']),
            if ((item['motivoFechamento'] ?? '').toString().isNotEmpty)
              _detalheRow('Motivo fechamento', item['motivoFechamento']),
          ],
        ),
      ),
    );
  }

  Widget _detalheRow(String label, dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
    SecurityMatrix sec,
    int selected,
  ) {
    final items = <BottomNavigationBarItem>[];

    void addItem({required IconData icon, required String label}) {
      final index = items.length;
      final active = index == selected;
      items.add(BottomNavigationBarItem(
        icon: _bottomNavIcon(icon, active: active),
        label: label,
      ));
    }

    // Slot 0 — Inicio
    addItem(icon: Icons.calendar_today, label: 'Inicio');
    // Slot 1 — Chat
    addItem(icon: Icons.chat, label: 'Chat');
    // Slot 2 — Comunicados
    addItem(icon: Icons.campaign, label: 'Comunicados');
    // Slot 3 — Slot dinamico (opcional)
    final dynamic = _dynamicSlotInfo(sec);
    if (dynamic != null) {
      addItem(icon: dynamic.icon, label: dynamic.label);
    }
    // Slot 4 (ou 3) — Mais
    final moreIndex = items.length;
    items.add(BottomNavigationBarItem(
      icon: _bottomNavIcon(Icons.more_horiz, active: moreIndex == selected),
      label: 'Mais',
    ));

    return items;
  }

  Widget _bottomNavIcon(IconData icon, {required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: active ? 46 : 40,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            active ? Border.all(color: GridColors.secondary, width: 1.2) : null,
      ),
      child: Icon(
        icon,
        size: active ? 21 : 20,
        color: active
            ? GridColors.secondary
            : Colors.white.withValues(alpha: 0.82),
      ),
    );
  }

  bool _hasPermissionFor(
    SecurityMatrix sec,
    AppScreen screen,
    String action,
  ) {
    return switch (action) {
      'insert' || 'create' => sec.canInsert(screen),
      'update' || 'edit' => sec.canUpdate(screen),
      'delete' || 'remove' => sec.canDelete(screen),
      _ => sec.canView(screen),
    };
  }

  static List<CustomAction> _comunicadoActionsBuilder() {
    return [
      CustomAction(
        icon: Icons.visibility_outlined,
        label: 'Visualizar comunicado',
        onPressed: (BuildContext ctx, Map<String, dynamic> item) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => WindowsComunicadoDetalheScreen(comunicado: item),
          ));
        },
        isVisible: (_) => true,
      ),
    ];
  }

  Future<void> _pushDynamicGrid({
    required String telaNome,
    required SecurityMatrix sec,
    AppScreen? screen,
    String? fetchEndpointOverride,
    String? createEndpointOverride,
    String? updateEndpointOverride,
    String? deleteEndpointOverride,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicGridDynamicScreen(
          key: ValueKey('mobile_dynamic_push_$telaNome'),
          telaNome: telaNome,
          hasPermission: (action) =>
              screen == null ? true : _hasPermissionFor(sec, screen, action),
          storageKey: 'mobile_dynamic_$telaNome',
          fetchEndpointOverride: fetchEndpointOverride,
          createEndpointOverride: createEndpointOverride,
          updateEndpointOverride: updateEndpointOverride,
          deleteEndpointOverride: deleteEndpointOverride,
        ),
      ),
    );
  }

  void onMenuOptionSelected(String option, SecurityMatrix sec) {
    Navigator.pop(context); // fecha o bottom sheet do menu
    Future<void>? nav;

    switch (option) {
      case "Pedidos":
        nav = _pushDynamicGrid(
          telaNome: 'pedido',
          sec: sec,
          screen: AppScreen.pedidos,
        );
        break;
      case "Solicitacoes":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _chamadoGridInline(sec: sec)),
        );
        break;
      case "Comunicados":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _comunicadoGridInline(sec: sec)),
        );
        break;
      case "GED":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _gedDynamicGrid(sec)),
        );
        break;
      case "Produtos":
        nav = _pushDynamicGrid(
          telaNome: 'produto',
          sec: sec,
          screen: AppScreen.produto,
        );
        break;
      case "Contas Pagar":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasPagar, action),
            ),
          ),
        );
        break;
      case "Contas Receber":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasReceber, action),
            ),
          ),
        );
        break;
      case "Régua de Cobrança":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: SafeArea(child: CobrancaAutomaticaScreen()),
            ),
          ),
        );
        break;
      case "Parceiros":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.parceiros, action),
            ),
          ),
        );
        break;
      case "Dashboard":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
        break;
      case "Atendimento":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DashboardAtendimentoPlaceholderScreen()),
        );
        break;
      case "Trading":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TradingDashboardScreen()),
        );
        break;
      case "Backtesting":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BacktestScreen(
              repository: BacktestRepository(ApiLinks.baseUrl,
                  headers: TenantContext.jsonHeaders),
            ),
          ),
        );
        break;
      case "PDV":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdvScreen()),
        );
        break;
      case "Config Fiscal":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigFiscalScreen()),
        );
        break;
      case "CRM/Funil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmPipelineScreen()),
        );
        break;
      case "Obrigacoes":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FiscalAutomationScreen()),
        );
        break;
      case "Contas Bancarias":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaBancariaGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasBancarias, action),
            ),
          ),
        );
        break;
      case "Bater Ponto":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PontoScreen()),
        );
        break;
      case "Funcionários":
        nav = _pushDynamicGrid(
          telaNome: 'funcionario',
          sec: sec,
          screen: AppScreen.funcionarios,
        );
        break;
      case "Mensalidades":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileMensalidadeScreen()),
        );
        break;
      case "Alvarás":
        nav = _pushDynamicGrid(
          telaNome: 'alvara',
          sec: sec,
        );
        break;
      case "Meu Perfil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeuPerfilScreen()),
        );
        break;
      case "Importar Extratos":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ExtratoImportacaoScreen(),
          ),
        );
        break;
      case "Voltar":
        return;
      case "Sair":
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair do aplicativo'),
            content: const Text('Deseja encerrar a sessão?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthUtility.clearUserInfo();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        return; // logout não reabre o menu
    }

    // Quando o usuário pressionar voltar em qualquer tela do menu "Mais",
    // reabrir o menu automaticamente.
    nav?.then((_) {
      if (mounted) _showMenuOptions(context, sec);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final screens = _buildScreens(sec);

    final safeIndex = selectedIndex.clamp(0, screens.length - 1);
    final navItems = _buildNavItems(sec, safeIndex);

    // BottomNavigationBar exige no mínimo 2 itens
    if (navItems.length < 2) {
      return const SemAcessoScreen();
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          const AppLoggerOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GridColors.primary,
          border: Border(
            top: BorderSide(color: GridColors.primaryDark, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: GridColors.primary,
          currentIndex: safeIndex,
          unselectedItemColor: Colors.white.withValues(alpha: 0.82),
          selectedItemColor: Colors.white,
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            if (index == navItems.length - 1) {
              _showMenuOptions(context, sec);
            } else {
              setState(() => selectedIndex = index);
            }
          },
          items: navItems,
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    // Grupos de modulos com seus itens (filtrados por permissao)
    final grupos = <_MenuGrupo>[
      _MenuGrupo(
        titulo: 'Comercial',
        icon: Icons.storefront_outlined,
        itens: [
          if (sec.canView(AppScreen.pedidos))
            const _MoreMenuAction(Icons.shopping_cart_outlined, 'Pedidos'),
          if (sec.canView(AppScreen.parceiros))
            const _MoreMenuAction(Icons.people, 'Parceiros'),
          if (sec.canView(AppScreen.produto))
            const _MoreMenuAction(Icons.inventory_2_outlined, 'Produtos'),
        ],
      ),
      _MenuGrupo(
        titulo: 'Financeiro',
        icon: Icons.account_balance_outlined,
        itens: [
          if (sec.canView(AppScreen.contasPagar))
            const _MoreMenuAction(Icons.payments, 'Contas Pagar'),
          if (sec.canView(AppScreen.contasReceber))
            const _MoreMenuAction(
                Icons.account_balance_wallet, 'Contas Receber'),
          if (sec.canView(AppScreen.contasBancarias))
            const _MoreMenuAction(Icons.account_balance, 'Contas Bancarias'),
          if (sec.canView(AppScreen.dashboard))
            const _MoreMenuAction(Icons.bar_chart, 'Dashboard'),
        ],
      ),
      _MenuGrupo(
        titulo: 'Atendimento',
        icon: Icons.support_agent_outlined,
        itens: [
          if (sec.canView(AppScreen.chamados))
            const _MoreMenuAction(Icons.support_agent, 'Solicitacoes'),
          if (sec.canView(AppScreen.ged))
            const _MoreMenuAction(Icons.folder_open, 'GED'),
          if (sec.canView(AppScreen.comunicados))
            const _MoreMenuAction(Icons.campaign, 'Comunicados'),
        ],
      ),
      _MenuGrupo(
        titulo: 'Pessoal',
        icon: Icons.badge_outlined,
        itens: [
          if (sec.canView(AppScreen.ponto))
            const _MoreMenuAction(Icons.access_time, 'Bater Ponto'),
          if (sec.canView(AppScreen.funcionarios))
            const _MoreMenuAction(Icons.badge, 'Funcionários'),
          if (sec.canView(AppScreen.mensalidades))
            const _MoreMenuAction(Icons.receipt_long, 'Mensalidades'),
        ],
      ),
      _MenuGrupo(
        titulo: 'Sistema',
        icon: Icons.settings_outlined,
        itens: const [
          _MoreMenuAction(Icons.verified_user, 'Alvarás'),
          _MoreMenuAction(Icons.account_circle, 'Meu Perfil'),
          _MoreMenuAction(Icons.exit_to_app, 'Sair', isDestructive: true),
        ],
      ),
    ];

    // Remove grupos sem nenhum item visivel
    final gruposVisiveis =
        grupos.where((g) => g.itens.isNotEmpty).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: GridColors.card,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (_, scrollCtrl) => Column(
            children: [
              // Cabecalho fixo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GridColors.divider,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: GridColors.secondarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.apps_rounded,
                            color: GridColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mais opcoes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: GridColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Acesse os modulos do sistema',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GridColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                          color: GridColors.textMuted,
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                  ],
                ),
              ),
              // Lista rolavel de grupos
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  children: [
                    for (final grupo in gruposVisiveis)
                      Theme(
                        data: Theme.of(sheetContext).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          leading: Icon(grupo.icon,
                              color: GridColors.secondary, size: 22),
                          title: Text(
                            grupo.titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: GridColors.textSecondary,
                            ),
                          ),
                          initiallyExpanded: true,
                          iconColor: GridColors.secondary,
                          collapsedIconColor: GridColors.textMuted,
                          children: [
                            for (final item in grupo.itens)
                              ListTile(
                                dense: true,
                                leading: Icon(
                                  item.icon,
                                  size: 20,
                                  color: item.isDestructive
                                      ? GridColors.error
                                      : GridColors.secondary,
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: item.isDestructive
                                        ? GridColors.error
                                        : GridColors.textSecondary,
                                  ),
                                ),
                                onTap: () =>
                                    onMenuOptionSelected(item.title, sec),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 0),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

class _MenuGrupo {
  final String titulo;
  final IconData icon;
  final List<_MoreMenuAction> itens;

  const _MenuGrupo({
    required this.titulo,
    required this.icon,
    required this.itens,
  });
}

class _MoreMenuAction {
  final IconData icon;
  final String title;
  final bool isDestructive;

  const _MoreMenuAction(
    this.icon,
    this.title, {
    this.isDestructive = false,
  });
}
