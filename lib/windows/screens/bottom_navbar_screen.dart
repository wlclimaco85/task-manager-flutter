import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import '../../../windows/screens/comunicado_screen.dart';
import '../../../windows/screens/conta_pagar_grid_screen.dart';
import '../../../windows/screens/conta_receber_grid_screen.dart';
import '../../../windows/screens/dieta_grid_screen.dart';
import '../../../windows/screens/diretorio_grid_screen.dart';
import '../../../windows/screens/empresa_grid_screen.dart';
import '../../../windows/screens/exame_grid_screen.dart';
import '../../../windows/screens/exercicio_grid_screen.dart';
import '../../web/screens/ged_arquivos_screen.dart';
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
import '../../../windows/screens/configuracoes_admin_screen.dart';
import '../../../windows/screens/cotacao_frete_grid_screen.dart';
import '../../../windows/screens/dividendo_grid_screen.dart';
import '../../../windows/screens/order_grid_screen.dart';
import '../../../windows/screens/pedido_grid_screen.dart';
import '../../../windows/screens/ticket_grid_screen.dart';
import '../../../windows/screens/alerta_aluno_grid_screen.dart';
import '../../../windows/screens/avaliacao_fisica_grid_screen.dart';
import '../../../windows/screens/conta_bancaria_grid_screen.dart';
import '../../../windows/screens/classificacao_grid_screen.dart';
import '../../../windows/screens/feriado_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_entrada_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_saida_grid_screen.dart';
import '../../../windows/screens/produto_grid_screen.dart';
import '../../../windows/screens/treino_grid_screen.dart';
import '../../../windows/screens/funcionario_grid_screen.dart';
import '../../web/screens/kanban_chamados_screen.dart';
import '../../web/screens/tela_editor_screen.dart';
import '../../mobile/screens/dashboard_screen.dart';
import '../../../widgets/app_sidebar.dart';
// Telas web reutilizadas no Windows
import '../../web/screens/nfe_finalidade_grid_screen.dart';
import '../../web/screens/nfe_serie_grid_screen.dart';
import '../../web/screens/nfe_tipo_operacao_grid_screen.dart';
import '../../web/screens/unidade_medida_grid_screen.dart';
import '../../web/screens/catalago_produto_grid_screen.dart';
import '../../web/screens/role_permissao_screen.dart';
import '../../web/screens/tipo_parceiro_grid_screen.dart';
import '../../web/screens/servico_contratado_grid_screen.dart';
import '../../web/screens/modulo_servico_grid_screen.dart';
import '../../web/screens/ponto_web_screen.dart';
import '../../web/screens/ponto_solicitacao_screen.dart';
import '../../web/screens/ponto_ajuste_screen.dart';
import '../../web/screens/configuracoes_sistema_screen.dart';
import '../../web/screens/chatMessageListScreen.dart';
import '../../web/screens/system_test_screen.dart';
import '../../web/screens/cadastro_empresa_wizard.dart';
import '../../web/screens/alvara_grid_screen.dart';
import '../../web/screens/nfe_import_screen.dart';

class WindowsBottomNavBarScreen extends StatefulWidget {
  const WindowsBottomNavBarScreen({super.key});

  @override
  State<WindowsBottomNavBarScreen> createState() =>
      _WindowsBottomNavBarScreenState();
}

class _WindowsBottomNavBarScreenState extends State<WindowsBottomNavBarScreen> {
  int _selectedIndex = 31; // Calendário como tela inicial
  bool _isSidebarCollapsed = false;
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  bool _isLoading = true;
  late List<Widget> _screens;

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
    });
    _startPeriodicFetch();
  }

  List<Widget> _buildScreens(dynamic userInfo) => [
        WindowsComunicadoGridScreen(),
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
        const GedArquivosScreen(), // 30: GED
        WindowsCalendarScreen(),
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
        WebNfeFinalidadeGridScreen(hasPermission: (perm) => true), // 54
        WebNfeSerieGridScreen(hasPermission: (perm) => true), // 55
        WebNfeTipoOperacaoGridScreen(hasPermission: (perm) => true), // 56
        WebUnidadeMedidaGridScreen(hasPermission: (perm) => true), // 57
        WebCatalagoProdutoGridScreen(hasPermission: (perm) => true), // 58
        const RolePermissaoScreen(), // 59
        const WebPontoScreen(), // 60
        const WebPontoSolicitacaoScreen(), // 61
        const WebPontoAjusteScreen(), // 62
        const ConfiguracoesSistemaScreen(), // 63
        WebChatListScreen(
            userName: AuthUtility.userInfo?.data?.email ?? 'Usuário'), // 64
        const SystemTestScreen(), // 65
        const CadastroEmpresaWizard(), // 66
        WebTipoParceiroGridScreen(hasPermission: (perm) => true), // 67
        WebServicoContratadoGridScreen(hasPermission: (perm) => true), // 68
        WebModuloServicoGridScreen(hasPermission: (perm) => true), // 69
        WebAlvaraGridScreen(hasPermission: (perm) => true), // 70
        const NfeImportScreen(),                             // 71
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
          await AlertCaller().fetchItensAVenda(context);
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
            onSelect: (idx) => setState(() => _selectedIndex = idx),
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
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: _screens[_selectedIndex.clamp(0, _screens.length - 1)],
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
