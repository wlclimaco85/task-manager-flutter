import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/auth_utility.dart';
import '../services/favorites_service.dart';
import '../utils/menu_config.dart';

/// Sidebar com submenus, busca e favoritos.
/// Usado tanto no Windows quanto no Web (drawer).
class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int unreadAlerts;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.unreadAlerts,
    required this.onNotificationTap,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _primary    = GridColors.primary;   // vermelho — bordas e destaques
  static const _bg         = GridColors.secondary;   // verde escuro — fundo sidebar
  static const _bgItem     = Color(0xFF004a20);   // verde mais escuro — hover
  static const _bgSelected = Color(0xFF003d1a);   // verde escuríssimo — selecionado
  static const _textColor  = Colors.white;        // branco — texto principal
  static const _textMuted  = Color(0xFFa8d5b5);   // verde claro — texto secundário

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Set<String> _favorites = {};
  final Set<String> _expandedGroups = {};
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    _userId = AuthUtility.userInfo?.data?.id?.toString() ?? 'guest';
    final favs = await FavoritesService.load(_userId);
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _toggleFavorite(String itemId) async {
    final newState = await FavoritesService.toggle(_userId, itemId);
    setState(() {
      if (newState) {
        _favorites.add(itemId);
      } else {
        _favorites.remove(itemId);
      }
    });
  }

  void _toggleGroup(String groupId) {
    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  void _navigate(MenuItem item) {
    if (item.screenIndex >= 0) {
      widget.onSelect(item.screenIndex);
    }
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<MenuItem> get _favoriteItems {
    return MenuConfig.allItems
        .where((m) => _favorites.contains(m.id))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isCollapsed ? 64 : 260,
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(right: BorderSide(color: Color(0xFF004a20), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!widget.isCollapsed) _buildSearch(),
          Expanded(
            child: widget.isCollapsed
                ? _buildCollapsedList()
                : _isSearching
                    ? _buildSearchResults()
                    : _buildFullMenu(),
          ),
          _buildCollapseButton(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    if (widget.isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _primary,
              child: Text(
                widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _iconBtn(Icons.notifications, widget.unreadAlerts > 0 ? _primary : _textMuted, widget.onNotificationTap, badge: widget.unreadAlerts),
            const SizedBox(height: 4),
            _iconBtn(Icons.logout, _textMuted, widget.onLogout),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF004a20), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _primary,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.userName, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(widget.userEmail, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textMuted, fontSize: 11)),
                  ],
                ),
              ),
              _iconBtn(Icons.notifications, widget.unreadAlerts > 0 ? _primary : _textMuted, widget.onNotificationTap, badge: widget.unreadAlerts),
              const SizedBox(width: 4),
              _iconBtn(Icons.logout, _textMuted, widget.onLogout),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: color, size: 18),
          ),
          if (badge > 0)
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  // ── Busca ─────────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar tela...',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _textMuted, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => _searchCtrl.clear(),
                  child: const Icon(Icons.close, color: _textMuted, size: 16),
                )
              : null,
          filled: true,
          fillColor: _bgItem,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ── Resultados de busca ───────────────────────────────────────────────────
  Widget _buildSearchResults() {
    final results = MenuConfig.search(_searchQuery);
    if (results.isEmpty) {
      return const Center(child: Text('Nenhuma tela encontrada', style: TextStyle(color: _textMuted, fontSize: 12)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: results.map((item) => _buildMenuItem(item, indent: false)).toList(),
    );
  }

  // ── Menu completo ─────────────────────────────────────────────────────────
  Widget _buildFullMenu() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        // Favoritos
        if (_favoriteItems.isNotEmpty) ...[
          _buildSectionHeader('⭐ Favoritos'),
          ..._favoriteItems.map((item) => _buildMenuItem(item, indent: true)),
          const Divider(color: Color(0xFF004a20), height: 16),
        ],
        // Grupos com submenus
        ...MenuConfig.groups.map((group) => _buildGroup(group)),
        // Itens soltos
        const Divider(color: Color(0xFF004a20), height: 16),
        _buildSectionHeader('Outros'),
        ...MenuConfig.loose.map((item) => _buildMenuItem(item, indent: true)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(color: _textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  Widget _buildGroup(MenuGroup group) {
    final isExpanded = _expandedGroups.contains(group.id);
    // Verifica se algum item do grupo está selecionado
    final hasSelected = group.items.any((i) => i.screenIndex == widget.selectedIndex);
    // Verifica se algum item do grupo é favorito
    final hasFavorite = group.items.any((i) => _favorites.contains(i.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do grupo
        InkWell(
          onTap: () => _toggleGroup(group.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasSelected ? _bgSelected.withValues(alpha: 0.5) : Colors.transparent,
            ),
            child: Row(
              children: [
                FaIcon(group.icon, size: 14, color: hasSelected ? _primary : _textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(group.label,
                      style: TextStyle(
                        color: hasSelected ? _primary : _textColor,
                        fontSize: 13,
                        fontWeight: hasSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ),
                if (hasFavorite)
                  const Icon(Icons.star, size: 10, color: Colors.amber),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: _textMuted, size: 16,
                ),
              ],
            ),
          ),
        ),
        // Itens do grupo
        if (isExpanded)
          ...group.items.map((item) => _buildMenuItem(item, indent: true)),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item, {required bool indent}) {
    final isSelected = item.screenIndex == widget.selectedIndex && item.screenIndex >= 0;
    final isFav = _favorites.contains(item.id);

    return InkWell(
      onTap: item.screenIndex >= 0 ? () => _navigate(item) : null,
      child: Container(
        padding: EdgeInsets.only(
          left: indent ? 32 : 14,
          right: 8,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _bgSelected : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: _primary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            FaIcon(item.icon, size: 13,
                color: isSelected ? _primary : item.screenIndex < 0 ? _textMuted.withValues(alpha: 0.5) : _textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    color: isSelected ? _primary : item.screenIndex < 0 ? _textMuted.withValues(alpha: 0.5) : _textColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
            // Estrela de favorito
            GestureDetector(
              onTap: () => _toggleFavorite(item.id),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  size: 14,
                  color: isFav ? Colors.amber : _textMuted.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista colapsada (só ícones) ───────────────────────────────────────────
  Widget _buildCollapsedList() {
    final allItems = [...MenuConfig.groups.expand((g) => g.items), ...MenuConfig.loose];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: allItems
          .where((i) => i.screenIndex >= 0)
          .map((item) {
            final isSelected = item.screenIndex == widget.selectedIndex;
            return Tooltip(
              message: item.label,
              preferBelow: false,
              child: InkWell(
                onTap: () => _navigate(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _bgSelected : Colors.transparent,
                    border: isSelected
                        ? const Border(left: BorderSide(color: _primary, width: 3))
                        : null,
                  ),
                  child: Center(
                    child: FaIcon(item.icon, size: 16,
                        color: isSelected ? _primary : _textMuted),
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }

  // ── Botão colapsar ────────────────────────────────────────────────────────
  Widget _buildCollapseButton() {
    return InkWell(
      onTap: widget.onToggleCollapse,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF004a20))),
        ),
        child: Center(
          child: Icon(
            widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
            color: _textMuted, size: 20,
          ),
        ),
      ),
    );
  }
}





