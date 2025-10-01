import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:task_manager_flutter/data/models/alert_model.dart';
import 'package:task_manager_flutter/data/models/auth_utility.dart';
import 'package:task_manager_flutter/data/services/alert_caller.dart';
import 'package:task_manager_flutter/ui/screens/auth_screens/login_screen.dart';

// Paleta da logo
class GridColors {
  static const Color primary = Color(0xFF93070A); // vermelho logo
  static const Color secondary = Color(0xFF005826); // verde logo
  static const Color textPrimary = Color(0xFFFFFFFF); // branco
  static const Color textSecondary = Color(0xFF000000); // preto
  static const Color error = Color(0xFFD32F2F);
  static const Color divider = Color(0xFFBDBDBD);
  static const Color card = Color(0xFFFFFFFF);
  static const Color filterBackground = Color(0xFFEFEFEF);
}

// AppBar customizado
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
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + 60); // altura maior
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
    fetchAlerts(); // primeira carga imediata
  }

  Future<void> fetchAlerts() async {
    try {
      if (AuthUtility.userInfo?.data?.id != null &&
          AuthUtility.userInfo!.data!.id! > 0) {
        final List<Alert> alertData =
            await AlertCaller().fetchItensAVenda(context);
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
    await AlertCaller().markNotificationAsRead(id);
    setState(() {
      notifications.removeWhere((n) => n.id == id);
      unreadAlerts = notifications.length;
    });
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

  void showNotificationDropdown(BuildContext context) {
    if (notificationOverlay != null) {
      notificationOverlay!.remove();
      notificationOverlay = null;
      return;
    }

    final overlay = Overlay.of(context);

    notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: kToolbarHeight + 68,
        right: 8,
        child: Material(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 320,
            height: 400,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Notificações",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: GridColors.error),
                      onPressed: () {
                        notificationOverlay?.remove();
                        notificationOverlay = null;
                      },
                    ),
                  ],
                ),
                const Divider(height: 1, color: GridColors.divider),
                // Botão deletar tudo
                ListTile(
                  leading:
                      const Icon(Icons.delete_sweep, color: GridColors.error),
                  title: const Text("Limpar Todas",
                      style: TextStyle(
                          color: GridColors.error,
                          fontWeight: FontWeight.w500)),
                  onTap: deleteAllNotifications,
                ),
                const Divider(height: 1, color: GridColors.divider),
                // Lista
                Expanded(
                  child: notifications.isNotEmpty
                      ? ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            return ListTile(
                              leading: const Icon(Icons.notifications,
                                  color: GridColors.primary),
                              title: Text(n.texto,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: IconButton(
                                icon: const Icon(Icons.clear,
                                    color: GridColors.error),
                                onPressed: () => deleteNotification(n.id),
                              ),
                              onTap: () => markNotificationAsRead(n.id),
                            );
                          },
                        )
                      : const Center(child: Text("Nenhuma notificação")),
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
    AuthUtility.clearUserInfo();
    MaterialPageRoute(builder: (context) => LoginScreen());
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
    // avatar vazio
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
      backgroundColor: GridColors.primary, // vermelho da logo
      title: Row(
        children: [
          Image.asset('assets/images/iconApp.png', width: 36, height: 36,
              errorBuilder: (_, __, ___) {
            return const Icon(Icons.apps, color: GridColors.textPrimary);
          }),
          const SizedBox(width: 12),
          if (isLoggedIn) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: _getUserAvatar().isNotEmpty
                  ? ClipOval(
                      child: Image.memory(_getUserAvatar(),
                          width: 36, height: 36, fit: BoxFit.cover))
                  : const Icon(Icons.person, color: GridColors.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AuthUtility.userInfo?.data?.codDadosPessoal?.nome ??
                      "Usuário",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GridColors.textPrimary),
                ),
                Text(
                  _getCompanyName(),
                  style: const TextStyle(
                      fontSize: 12, color: GridColors.textPrimary),
                ),
              ],
            )
          ] else ...[
            Text(widget.screenTitle ?? "Comunicados",
                style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold)),
          ],
        ],
      ),
      actions: [
        if (isLoggedIn) ...[
          // Botão de Refresh
          if (widget.onRefresh != null)
            IconButton(
              iconSize: 22, // Tamanho ajustado :cite[1]:cite[7]
              icon: widget.isLoading ?? false
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Icon(Icons.refresh,
                      color: Theme.of(context).colorScheme.onPrimary),
              onPressed: widget.isLoading ?? false ? null : widget.onRefresh,
              tooltip: 'Recarregar dados',
            ),
          if (widget.showFilterButton ?? true)
            // Botão de Configuração de Campos
            IconButton(
              iconSize: 22, // Tamanho ajustado :cite[1]:cite[7]
              icon:
                  const Icon(Icons.view_column, color: GridColors.textPrimary),
              onPressed: () {
                // Callback para configuração de campos
              },
              tooltip: 'Configurar campos visíveis',
            ),

          // Botão de Filtros

          IconButton(
            icon: Icon(Icons.filter_list,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: widget
                .onFilterToggle, // Este callback vem do GenericMobileGridScreen
            tooltip: 'Mostrar/ocultar filtros',
          ),

          // Botão de Notificações (COM STACK - apenas para a badge)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 22, // Tamanho ajustado :cite[1]:cite[7]
                icon: const Icon(Icons.notifications,
                    color: GridColors.textPrimary),
                onPressed: () => showNotificationDropdown(context),
              ),
              if (unreadAlerts > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadAlerts > 9 ? '9+' : '$unreadAlerts',
                      style: const TextStyle(
                        color: GridColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Botão de Logout (FORA DA STACK - funciona corretamente)
          IconButton(
            iconSize: 22, // Tamanho ajustado :cite[1]:cite[7]
            icon: const Icon(Icons.logout, color: GridColors.textPrimary),
            onPressed: _handleLogout, // AGORA FUNCIONA
            tooltip: 'Sair',
          ),
        ] else ...[
          IconButton(
            iconSize: 22, // Tamanho ajustado :cite[1]:cite[7]
            icon: const Icon(Icons.login, color: GridColors.textPrimary),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ]
      ],
    );
  }
}
