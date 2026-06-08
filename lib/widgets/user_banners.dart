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

  String? _formatNotificationDate(String? data) {
    if (data == null || data.isEmpty) return null;
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return null;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
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
        top: kToolbarHeight + ((widget.showFilterButton == true) ? 68 : 16),
        right: 8,
        child: Material(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 420, minHeight: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GridColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
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
                Expanded(
                  child: notifications.isNotEmpty
                      ? ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: GridColors.divider.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            final dataFormatada =
                                _formatNotificationDate(n.data);
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              leading: const Icon(Icons.notifications,
                                  color: GridColors.primary, size: 22),
                              title: Text(
                                n.texto,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: GridColors.textSecondary),
                              ),
                              subtitle: dataFormatada != null
                                  ? Text(
                                      dataFormatada,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: GridColors.textMuted),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: GridColors.error, size: 18),
                                constraints: const BoxConstraints(
                                    maxWidth: 32, maxHeight: 32),
                                padding: EdgeInsets.zero,
                                onPressed: () => deleteNotification(n.id),
                              ),
                              onTap: () => markNotificationAsRead(n.id),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 48,
                                  color: GridColors.textSecondary
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              const Text(
                                'Nenhuma notificação',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: GridColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
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
              'assets/images/iconApp.png',
              width: 36,
              height: 36,
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
                  widget.screenTitle ?? "Comunicados",
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

// Nova barra de ações secundária
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
