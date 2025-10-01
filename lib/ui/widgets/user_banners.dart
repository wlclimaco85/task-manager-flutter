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

  // Filter Box Widget
  Widget _buildFilterBox() {
    return Container(
      width: double.infinity, // Takes full width
      constraints:
          BoxConstraints(maxWidth: 400), // Maximum width for larger screens
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: GridColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: GridColors.textSecondary,
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, size: 20, color: GridColors.error),
                onPressed: () {
                  // Add logic to close/hide filters if needed
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Filter Content - Add your filter widgets here
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Example filter field
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),

              // Add more filter widgets as needed
              // DropdownButton, DatePicker, etc.
            ],
          ),

          // Filter Actions
          Container(
            padding: EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Clear filters logic
                  },
                  child: const Text('Limpar',
                      style: TextStyle(color: GridColors.error)),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Apply filters logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: Text('Aplicar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.userInfo?.data?.id != null &&
        AuthUtility.userInfo!.data!.id! > 0;

    return AppBar(
      backgroundColor: GridColors.primary,
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
                    color: GridColors.textPrimary,
                  ),
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
          // Notificações
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 22,
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
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      unreadAlerts > 9 ? '9+' : '$unreadAlerts',
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Logout
          IconButton(
            iconSize: 22,
            icon: const Icon(Icons.logout, color: GridColors.textPrimary),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ]
      ],
      bottom: widget.showFilterButton == true
          ? PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: GridColors.divider, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.onRefresh != null)
                      IconButton(
                        iconSize: 28,
                        icon: widget.isLoading ?? false
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    GridColors.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.refresh,
                                color: GridColors.primary),
                        onPressed:
                            widget.isLoading ?? false ? null : widget.onRefresh,
                        tooltip: 'Recarregar dados',
                      ),
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.view_column,
                          color: GridColors.primary),
                      onPressed: () {
                        // ação configurar colunas
                      },
                      tooltip: 'Configurar campos visíveis',
                    ),
                    IconButton(
                      iconSize: 28,
                      icon: const Icon(Icons.filter_list,
                          color: GridColors.primary),
                      onPressed: widget.onFilterToggle,
                      tooltip: 'Mostrar/ocultar filtros',
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
