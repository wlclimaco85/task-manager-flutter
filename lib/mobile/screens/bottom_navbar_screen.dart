import 'dart:async';

import 'package:flutter/material.dart';

import 'package:task_manager_flutter/constants/custom_colors.dart' hide GridColors;
import 'package:task_manager_flutter/models/alert_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/services/alert_caller.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

import 'sem_acesso_screen.dart';
import 'chamado_grid_screen_dynamic.dart';
import 'chatMessageListScreen.dart';
import 'comunicado_screen.dart';
import 'conta_bancaria_grid_screen.dart';
import 'conta_pagar_grid_screen.dart';
import 'conta_receber_grid_screen.dart';
import 'dashboard_screen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import 'documento_screen.dart';
import 'file_upload_screen.dart';
import 'parceiro_grid_screen.dart';
import 'ponto_screen.dart';
import 'funcionario_grid_screen.dart';
import 'produto_grid_screen.dart';
import '../../widgets/crm/crm_pipeline_screen.dart';
import '../../widgets/fiscal/fiscal_automation_screen.dart';

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
      final data = await AlertCaller().fetchItensAVenda(context);
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
                      'Notificações',
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
                    child: Text('Sem notificações',
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
                                _notifications.removeWhere(
                                    (x) => x.id == n.id);
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

  List<Widget> _buildScreens(SecurityMatrix sec) {
    return [
      if (sec.canView(AppScreen.calendario)) const CalendarScreen(),
      if (sec.canView(AppScreen.chat))
        AuthUtility.userInfo?.login?.email != null
            ? ChatListScreen(userName: AuthUtility.userInfo?.login?.email ?? '')
            : const ChatListScreen(userName: 'Usuário'),
      if (sec.canView(AppScreen.comunicados)) const ComunicadoScreen(),
      if (sec.canView(AppScreen.chamados))
        const ChamadosScreenDinamic(),
      if (sec.canView(AppScreen.ged)) const FileManagerScreen(),
      Container(), // slot do botão "Mais"
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems(SecurityMatrix sec) {
    return [
      if (sec.canView(AppScreen.calendario))
        const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), label: "Calendario"),
      if (sec.canView(AppScreen.chat))
        const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
      if (sec.canView(AppScreen.comunicados))
        const BottomNavigationBarItem(
            icon: Icon(Icons.campaign), label: "Comunicados"),
      if (sec.canView(AppScreen.chamados))
        const BottomNavigationBarItem(
            icon: Icon(Icons.support_agent), label: "Solicitações"),
      if (sec.canView(AppScreen.ged))
        const BottomNavigationBarItem(
            icon: Icon(Icons.folder_open), label: "GED"),
      const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz), label: "Mais"),
    ];
  }

  void onMenuOptionSelected(String option, SecurityMatrix sec) {
    Navigator.pop(context);
    switch (option) {
      case "Contas Pagar":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasPagar),
                'update' => sec.canUpdate(AppScreen.contasPagar),
                'delete' => sec.canDelete(AppScreen.contasPagar),
                _ => sec.canView(AppScreen.contasPagar),
              },
            ),
          ),
        );
        break;
      case "Contas Receber":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasReceber),
                'update' => sec.canUpdate(AppScreen.contasReceber),
                'delete' => sec.canDelete(AppScreen.contasReceber),
                _ => sec.canView(AppScreen.contasReceber),
              },
            ),
          ),
        );
        break;
      case "Parceiros":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.parceiros),
                'update' => sec.canUpdate(AppScreen.parceiros),
                'delete' => sec.canDelete(AppScreen.parceiros),
                _ => sec.canView(AppScreen.parceiros),
              },
            ),
          ),
        );
        break;
      case "Produtos":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileProdutoGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.produto),
                'update' => sec.canUpdate(AppScreen.produto),
                'delete' => sec.canDelete(AppScreen.produto),
                _ => sec.canView(AppScreen.produto),
              },
            ),
          ),
        );
        break;
      case "Dashboard":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
        break;
      case "Trading":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TradingDashboardScreen()),
        );
        break;
      case "CRM/Funil":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmPipelineScreen()),
        );
        break;
      case "Obrigacoes":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FiscalAutomationScreen()),
        );
        break;
      case "Contas Bancarias":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaBancariaGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.contasBancarias),
                'update' => sec.canUpdate(AppScreen.contasBancarias),
                'delete' => sec.canDelete(AppScreen.contasBancarias),
                _ => sec.canView(AppScreen.contasBancarias),
              },
            ),
          ),
        );
        break;
      case "Bater Ponto":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PontoScreen()),
        );
        break;
      case "Funcionários":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FuncionarioGridScreen(
              hasPermission: (action) => switch (action) {
                'insert' => sec.canInsert(AppScreen.funcionarios),
                'update' => sec.canUpdate(AppScreen.funcionarios),
                'delete' => sec.canDelete(AppScreen.funcionarios),
                _ => sec.canView(AppScreen.funcionarios),
              },
            ),
          ),
        );
        break;
      case "Sair":
      case "Voltar":
        Navigator.pop(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final screens = _buildScreens(sec);
    final navItems = _buildNavItems(sec);

    final safeIndex = selectedIndex.clamp(0, screens.length - 1);

    // BottomNavigationBar exige no mínimo 2 itens
    if (navItems.length < 2) {
      return const SemAcessoScreen();
    }

    return Scaffold(
      body: screens[safeIndex],
      floatingActionButton: _unreadCount > 0
          ? FloatingActionButton.small(
              backgroundColor: GridColors.primary,
              onPressed: () => _showNotificationsSheet(context),
              child: Badge(
                label: Text('$_unreadCount',
                    style: const TextStyle(fontSize: 10)),
                child: const Icon(Icons.notifications,
                    color: Colors.white, size: 20),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: CustomColors().getLightGreenBackground(),
          border: Border(
            top: BorderSide(
                color: CustomColors().getDarkGreenBorder(), width: 2),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: CustomColors().getLightGreenBackground(),
          currentIndex: safeIndex,
          unselectedItemColor: Colors.grey,
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          selectedItemColor: Colors.green,
          showSelectedLabels: true,
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
    final menuItems = <Widget>[
      if (sec.canView(AppScreen.contasPagar))
        _menuItem(Icons.payments, "Contas Pagar", sec),
      if (sec.canView(AppScreen.contasReceber))
        _menuItem(Icons.account_balance_wallet, "Contas Receber", sec),
      if (sec.canView(AppScreen.parceiros))
        _menuItem(Icons.people, "Parceiros", sec),
      if (sec.canView(AppScreen.produto))
        _menuItem(Icons.inventory_2, "Produtos", sec),
      if (sec.canView(AppScreen.dashboard))
        _menuItem(Icons.bar_chart, "Dashboard", sec),
      if (sec.canView(AppScreen.trading))
        _menuItem(Icons.show_chart, "Trading", sec),
      if (sec.canView(AppScreen.pedidos))
        _menuItem(Icons.trending_up, "CRM/Funil", sec),
      if (sec.canView(AppScreen.obrigacoesFiscais))
        _menuItem(Icons.assignment_turned_in, "Obrigacoes", sec),
      if (sec.canView(AppScreen.contasBancarias))
        _menuItem(Icons.account_balance, "Contas Bancarias", sec),
      if (sec.canView(AppScreen.ponto))
        _menuItem(Icons.access_alarm_rounded, "Bater Ponto", sec),
      if (sec.canView(AppScreen.funcionarios))
        _menuItem(Icons.badge, "Funcionários", sec),
      _menuItem(Icons.exit_to_app, "Sair", sec),
      _menuItem(Icons.arrow_back, "Voltar", sec),
    ];

    showGeneralDialog(
      barrierLabel: "Menu",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: CustomColors().getLightGreenBackground(),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Mais Opções",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CustomColors().getDarkGreenBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: CustomColors().getDarkGreenBorder(),
                      thickness: 1.2,
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.85,
                      children: menuItems,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(
            parent: anim,
            curve: Curves.fastOutSlowIn,
          )),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String title, SecurityMatrix sec) {
    return GestureDetector(
      onTap: () => onMenuOptionSelected(title, sec),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomColors().getDarkGreenBorder().withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: CustomColors().getDarkGreenBorder(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CustomColors().getDarkGreenBorder(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
