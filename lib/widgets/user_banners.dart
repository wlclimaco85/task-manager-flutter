import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../services/alert_caller.dart';
import '../../../auth_screens/login_screen.dart';
import '../../mobile/screens/user_edit_screen.dart';
import '../../../utils/grid_colors.dart'; // ★ adicionado para aplicar o tema

// AppBar customizado (apenas cabeçalho)
class UserBannerAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onTapped;
  final String? screenTitle;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onEmpresaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onFilterToggle;
  final bool? showFilterButton;

  const UserBannerAppBar({
    super.key,
    this.onTapped,
    this.screenTitle,
    this.onRefresh,
    this.isLoading,
    this.onEmpresaTap,
    this.onUserTap,
    this.onFilterToggle,
    this.showFilterButton = true,
  });

  @override
  _UserBannerAppBarState createState() => _UserBannerAppBarState();

  @override
  Size get preferredSize {
    // Ajusta a altura baseada no showFilterButton
    const baseHeight = kToolbarHeight;
    final filterBarHeight = (showFilterButton == true) ? 52.0 : 0.0;
    return Size.fromHeight(baseHeight + filterBarHeight);
  }
}

class _UserBannerAppBarState extends State<UserBannerAppBar> {
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPeriodicFetch();
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      fetchAlerts();
    });
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo!.data!.id! > 0) {
        final List<Alert> alertData =
            await AlertCaller().fetchNotificacoes(context);
        setState(() {
          notifications = alertData;
          unreadAlerts = notifications.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    final notificacao = notifications.where((n) => n.id == id).firstOrNull;
    if (notificacao == null) return;

    final sucesso = await AlertCaller().marcarNotificacaoLida(notificacao);
    if (!sucesso) {
      _mostrarErroNotificacao('Não foi possível marcar a notificação como lida.');
      return;
    }
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
  }

  Future<void> deleteNotification(int id) async {
    final notificacao = notifications.where((n) => n.id == id).firstOrNull;
    if (notificacao == null) return;

    final sucesso = await AlertCaller().marcarNotificacaoLida(notificacao);
    if (!sucesso) {
      _mostrarErroNotificacao('Não foi possível excluir a notificação.');
      return;
    }
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
  }

  void _mostrarErroNotificacao(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: GridColors.error),
    );
  }

  String? _formatNotificationDate(String? data) {
    if (data == null || data.isEmpty) return null;
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return null;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  Future<void> deleteAllNotifications() async {
    final sucesso = await AlertCaller().marcarTodasNotificacoesLidas();
    if (!sucesso) {
      _mostrarErroNotificacao('Não foi possível marcar todas as notificações como lidas.');
      return;
    }
    setState(() {
      notifications.clear();
      unreadAlerts = 0;
    });
  }

  /// Retorna ícone e cor representando o tipo de notificação.
  _NotificationTipoMeta _resolverTipo(String status) {
    final s = status.toUpperCase();
    if (s.contains('ALVAR') || s.contains('CERTID')) {
      return _NotificationTipoMeta(
          Icons.verified_outlined, GridColors.warning, 'Documento');
    }
    if (s.contains('VENC') || s.contains('PRAZO')) {
      return _NotificationTipoMeta(
          Icons.schedule_outlined, GridColors.error, 'Vencimento');
    }
    if (s.contains('CHAT') || s.contains('MENSAG')) {
      return _NotificationTipoMeta(
          Icons.chat_bubble_outline, GridColors.info, 'Mensagem');
    }
    if (s.contains('GED') || s.contains('ARQUIVO')) {
      return _NotificationTipoMeta(
          Icons.attach_file_outlined, GridColors.secondary, 'Arquivo');
    }
    if (s.contains('COMUNICADO')) {
      return _NotificationTipoMeta(
          Icons.campaign_outlined, GridColors.primaryLight, 'Comunicado');
    }
    return _NotificationTipoMeta(
        Icons.notifications_outlined, GridColors.primary, 'Aviso');
  }

  /// Formata data relativa: "agora", "há 2h", "ontem", "dd/MM".
  String _dataRelativa(String? data) {
    if (data == null || data.isEmpty) return '';
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(parsed);
  }

  void showNotificationDropdown(BuildContext context) {
    if (notificationOverlay != null) {
      notificationOverlay!.remove();
      notificationOverlay = null;
      return;
    }

    // Mobile: usa bottom sheet; desktop/web: overlay posicionado
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _mostrarBottomSheet(context);
      return;
    }

    final overlay = Overlay.of(context);
    final topOffset =
        kToolbarHeight + ((widget.showFilterButton == true) ? 68 : 12);

    notificationOverlay = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          notificationOverlay?.remove();
          notificationOverlay = null;
        },
        child: Stack(
          children: [
            Positioned(
              top: topOffset,
              right: 8,
              child: GestureDetector(
                onTap: () {}, // impede fechar ao clicar no painel
                child: _NotificationPanel(
                  notifications: notifications,
                  onMarcarLida: (id) {
                    markNotificationAsRead(id);
                    notificationOverlay?.remove();
                    notificationOverlay = null;
                  },
                  onDeletar: (id) {
                    deleteNotification(id);
                    notificationOverlay?.remove();
                    notificationOverlay = null;
                  },
                  onMarcarTodas: () {
                    deleteAllNotifications();
                    notificationOverlay?.remove();
                    notificationOverlay = null;
                  },
                  onFechar: () {
                    notificationOverlay?.remove();
                    notificationOverlay = null;
                  },
                  resolverTipo: _resolverTipo,
                  dataRelativa: _dataRelativa,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(notificationOverlay!);
  }

  void _mostrarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (__, scrollController) => Container(
          decoration: const BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Alça de drag
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GridColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _NotificationPanel(
                  notifications: notifications,
                  onMarcarLida: (id) => markNotificationAsRead(id),
                  onDeletar: (id) => deleteNotification(id),
                  onMarcarTodas: () => deleteAllNotifications(),
                  onFechar: () => Navigator.pop(context),
                  resolverTipo: _resolverTipo,
                  dataRelativa: _dataRelativa,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    AuthUtility.clearUserInfo();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Uint8List _getUserAvatar() {
    final base64String = AuthUtility.userInfo?.data?.codDadosPessoal?.photo;
    if (base64String != null && base64String.trim().isNotEmpty) {
      try {
        final UriData? data =
            Uri.parse("data:image/png;base64,$base64String").data;
        if (data != null) return data.contentAsBytes();
      } catch (_) {}
    }
    return Uint8List(0);
  }

  String _getCompanyName() {
    return AuthUtility.userInfo?.login?.empresa?.nome ?? "Empresa";
  }

  @override
  void dispose() {
    notificationOverlay?.remove();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        AuthUtility.userInfo!.data!.id! > 0;

    return AppBar(
      backgroundColor: GridColors.primary,
      title: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 120,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_contabilidade.jpg',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.apps, color: GridColors.textPrimary);
              },
            ),
            const SizedBox(width: 12),
            if (isLoggedIn) ...[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // CORREÇÃO: GestureDetector apenas no CircleAvatar
                    GestureDetector(
                      onTap: () {
                        // Prepara os dados atuais do usuário
                        final userData = {
                          'id': AuthUtility.userInfo?.data?.codDadosPessoal?.id,
                          'nome':
                              AuthUtility.userInfo?.data?.codDadosPessoal?.nome,
                          'cpf':
                              AuthUtility.userInfo?.data?.codDadosPessoal?.cpf,
                          'telefone1': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.telefone1,
                          'logradouro': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.logradouro,
                          'numero': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.numero,
                          'cep':
                              AuthUtility.userInfo?.data?.codDadosPessoal?.cep,
                          'bairro': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.bairro,
                          'cidade': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.cidade,
                          'estado': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.estado,
                          'pais':
                              AuthUtility.userInfo?.data?.codDadosPessoal?.pais,
                          'email': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.email,
                          'photo': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.photo,
                          'incrMun': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.incrMun,
                          'razaoSocial': AuthUtility
                              .userInfo?.data?.codDadosPessoal?.razaoSocial,
                        };

                        // Navega para a tela de edição
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserEditScreen(initialData: userData),
                          ),
                        ).then((updatedData) {
                          if (updatedData != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso!'),
                                backgroundColor: GridColors.success,
                              ),
                            );
                          }
                        });
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: _getUserAvatar().isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  _getUserAvatar(),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  // CORREÇÃO: Adicionar errorBuilder para evitar NaN
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      color: GridColors.primary,
                                      size: 16,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: GridColors.primary,
                                size: 16,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AuthUtility.userInfo?.data?.codDadosPessoal?.nome ??
                                "Usuário",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GridColors.textPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          Text(
                            _getCompanyName(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: GridColors.textPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ] else ...[
              Flexible(
                child: Text(
                  widget.screenTitle ?? "",
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (isLoggedIn) ...[
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.notifications,
                    color: GridColors.textPrimary),
                onPressed: () => showNotificationDropdown(context),
              ),
              if (unreadAlerts > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      unreadAlerts > 9 ? '9+' : '$unreadAlerts',
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            iconSize: 20,
            icon: const Icon(Icons.logout, color: GridColors.textPrimary),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ]
      ],
      bottom: (widget.showFilterButton == true)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: FilterActionBar(
                onRefresh: widget.onRefresh,
                isLoading: widget.isLoading,
                onFilterToggle: widget.onFilterToggle,
              ),
            )
          : null,
    );
  }
}

// =============================================================================
// NOTIFICAÇÕES — tipos e painel redesenhado
// =============================================================================

class _NotificationTipoMeta {
  final IconData icone;
  final Color cor;
  final String rotulo;

  const _NotificationTipoMeta(this.icone, this.cor, this.rotulo);
}

/// Painel de notificações com visual tipo banco digital.
/// Funciona tanto como overlay (web/desktop) quanto embutido em bottom sheet (mobile).
class _NotificationPanel extends StatelessWidget {
  final List<Alert> notifications;
  final void Function(int id) onMarcarLida;
  final void Function(int id) onDeletar;
  final VoidCallback onMarcarTodas;
  final VoidCallback onFechar;
  final _NotificationTipoMeta Function(String status) resolverTipo;
  final String Function(String? data) dataRelativa;
  final ScrollController? scrollController;

  const _NotificationPanel({
    required this.notifications,
    required this.onMarcarLida,
    required this.onDeletar,
    required this.onMarcarTodas,
    required this.onFechar,
    required this.resolverTipo,
    required this.dataRelativa,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 520, minHeight: 180),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCabecalho(context),
            if (notifications.isNotEmpty) _buildAcoes(),
            const Divider(height: 1, thickness: 1, color: GridColors.divider),
            Flexible(
              child: notifications.isNotEmpty
                  ? _buildLista()
                  : _buildVazio(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        color: GridColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: GridColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Notificações',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (notifications.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${notifications.length}',
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onFechar,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close,
                  color: GridColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: onMarcarTodas,
            icon: const Icon(Icons.done_all, size: 16, color: GridColors.success),
            label: const Text(
              'Marcar todas como lidas',
              style: TextStyle(
                color: GridColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        final meta = resolverTipo(n.status);
        final dataStr = dataRelativa(n.data);
        // Primeiro item ou itens não lidos ficam com fundo levemente colorido
        final isNaoLido = n.status.toUpperCase() == 'NOVO' || index == 0;

        return InkWell(
          onTap: () => onMarcarLida(n.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNaoLido
                  ? meta.cor.withValues(alpha: 0.06)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                    color: GridColors.divider.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone colorido por tipo
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: meta.cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icone, color: meta.cor, size: 20),
                ),
                const SizedBox(width: 12),
                // Texto principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: meta.cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meta.rotulo,
                              style: TextStyle(
                                color: meta.cor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (isNaoLido) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: meta.cor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (dataStr.isNotEmpty)
                            Text(
                              dataStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: GridColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: GridColors.textSecondary,
                          fontWeight: isNaoLido
                              ? FontWeight.w600
                              : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Botão deletar
                InkWell(
                  onTap: () => onDeletar(n.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: GridColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: GridColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 36,
              color: GridColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tudo em dia!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nenhuma notificação pendente.',
            style: TextStyle(fontSize: 13, color: GridColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// APP BAR ACTIONS — notificação + logout reutilizáveis em qualquer AppBar
// =============================================================================

/// Ícones de notificação (com badge) e logout para adicionar em `actions` de
/// qualquer AppBar sem precisar usar UserBannerAppBar completo.
///
/// Uso: `actions: [const AppBarActions(), ...outrasActions]`
class AppBarActions extends StatefulWidget {
  const AppBarActions({super.key});

  @override
  State<AppBarActions> createState() => _AppBarActionsState();
}

class _AppBarActionsState extends State<AppBarActions> {
  List<Alert> _alerts = [];
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    try {
      final userId = AuthUtility.userInfo?.data?.id;
      if (userId == null || userId <= 0) return;
      if (!mounted) return;
      final alerts = await AlertCaller().fetchNotificacoes(context);
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _unreadCount = alerts.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _markRead(int id) async {
    Alert? alert;
    for (final a in _alerts) {
      if (a.id == id) {
        alert = a;
        break;
      }
    }
    if (alert != null) {
      await AlertCaller().marcarNotificacaoLida(alert);
    }
    if (mounted) {
      setState(() {
        _alerts.removeWhere((a) => a.id == id);
        _unreadCount = _alerts.length;
      });
    }
  }

  void _markAll() {
    if (mounted) {
      setState(() {
        _alerts.clear();
        _unreadCount = 0;
      });
    }
  }

  String _dataRelativa(String? data) {
    if (data == null || data.isEmpty) return '';
    final d = DateTime.tryParse(data);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(d);
  }

  _NotificationTipoMeta _resolverTipo(String status) {
    final s = status.toUpperCase();
    if (s.contains('CHAMADO') || s.contains('TICKET'))
      return _NotificationTipoMeta(
          Icons.support_agent, GridColors.info, 'Chamado');
    if (s.contains('PAGAR') || s.contains('VENCIMENTO'))
      return _NotificationTipoMeta(
          Icons.payments_outlined, GridColors.error, 'A Pagar');
    if (s.contains('RECEBER'))
      return _NotificationTipoMeta(
          Icons.account_balance_wallet_outlined, GridColors.success, 'A Receber');
    if (s.contains('AVISO') || s.contains('COMUNICADO'))
      return _NotificationTipoMeta(
          Icons.campaign_outlined, GridColors.primaryLight, 'Aviso');
    return _NotificationTipoMeta(
        Icons.notifications_outlined, GridColors.primaryLight, 'Notificação');
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => _NotificationPanel(
          notifications: _alerts,
          onMarcarLida: _markRead,
          onDeletar: _markRead,
          onMarcarTodas: _markAll,
          onFechar: () => Navigator.pop(ctx),
          resolverTipo: _resolverTipo,
          dataRelativa: _dataRelativa,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    AuthUtility.clearUserInfo();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        (AuthUtility.userInfo!.data!.id ?? 0) > 0;
    if (!isLoggedIn) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              iconSize: 22,
              icon: const Icon(Icons.notifications,
                  color: GridColors.textPrimary),
              onPressed: () => _showNotifications(context),
              tooltip: 'Notificações',
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          iconSize: 22,
          icon:
              const Icon(Icons.logout, color: GridColors.textPrimary),
          onPressed: () => _logout(context),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}

// =============================================================================
// Nova barra de ações secundária
// =============================================================================
class FilterActionBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onFilterToggle;

  const FilterActionBar({
    super.key,
    this.onRefresh,
    this.isLoading,
    this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: GridColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onRefresh != null)
            IconButton(
              iconSize: 28,
              icon: isLoading ?? false
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(GridColors.primary),
                      ),
                    )
                  : const Icon(Icons.refresh, color: GridColors.primary),
              onPressed: isLoading ?? false ? null : onRefresh,
              tooltip: 'Recarregar dados',
            ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.view_column, color: GridColors.primary),
            onPressed: () {
              // ação configurar colunas
            },
            tooltip: 'Configurar campos visíveis',
          ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.filter_list, color: GridColors.primary),
            onPressed: onFilterToggle,
            tooltip: 'Mostrar/ocultar filtros',
          ),
        ],
      ),
    );
  }
}
