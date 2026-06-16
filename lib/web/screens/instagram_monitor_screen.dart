import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/instagram_service.dart';

class InstagramMonitorScreen extends StatefulWidget {
  const InstagramMonitorScreen({super.key});

  @override
  State<InstagramMonitorScreen> createState() => _InstagramMonitorScreenState();
}

class _InstagramMonitorScreenState extends State<InstagramMonitorScreen> with SingleTickerProviderStateMixin {
  // Controladores e estado do Match
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  InstagramProfile? _profile;
  bool _loading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _localApiStatus = false;

  // Estado da Timeline
  List<TimelineEvent> _events = [];
  bool _snapshotting = false;
  String? _lastSnapshotTime;
  String _currentUsername = '';

  // Perfis monitorados
  List<Map<String, dynamic>> _trackedProfiles = [];
  bool _loadingTracked = false;

  // Logs de alteracoes
  List<Map<String, dynamic>> _changeLogs = [];
  bool _loadingLogs = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _checkLocalApi();
    _loadTrackedProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkLocalApi() async {
    await InstagramService.checkLocalApi();
    if (mounted) setState(() => _localApiStatus = InstagramService.hasLocalApi);
  }

  /// Extrai username de qualquer formato: URL, @user, ou user puro
  String _cleanUsername(String input) {
    var clean = input.trim();
    // Remove https://www.instagram.com/ ou http://...
    clean = clean.replaceAll(RegExp(r'https?://(www\.)?instagram\.com/'), '');
    // Remove barras finais
    clean = clean.replaceAll(RegExp(r'/+$'), '');
    // Remove @
    clean = clean.replaceAll('@', '');
    // Remove query params
    clean = clean.split('?').first;
    return clean.trim();
  }

  /// Verifica se o perfil buscado ja esta monitorado
  bool _isProfileTracked(String username) {
    return _trackedProfiles.any((p) => p['username'] == username);
  }

  /// Retorna o id do perfil monitorado (ou null)
  int? _getTrackedId(String username) {
    for (final p in _trackedProfiles) {
      if (p['username'] == username) return p['id'] as int?;
    }
    return null;
  }

  /// Remove perfil do monitoramento com confirmacao
  Future<void> _untrackProfile(String username, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Color(0xFFE1306C), size: 24),
            const SizedBox(width: 10),
            const Text('Remover monitoramento', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Text(
          'Remover @$username do monitoramento?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover', style: TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await InstagramService.untrackProfile(id);
      if (success) {
        await _loadTrackedProfiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('@$username removido do monitoramento'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao remover perfil'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Busca perfis monitorados do backend
  Future<void> _loadTrackedProfiles() async {
    setState(() => _loadingTracked = true);
    final profiles = await InstagramService.fetchTrackedProfiles();
    if (mounted) {
      setState(() {
        _trackedProfiles = profiles;
        _loadingTracked = false;
      });
    }
  }

  Future<void> _loadChangeLogs(String username) async {
    setState(() => _loadingLogs = true);
    final logs = await InstagramService.fetchChangeLogs(username);
    if (mounted) {
      setState(() {
        _changeLogs = logs;
        _loadingLogs = false;
      });
    }
  }

  // --- Ações de busca e snapshot ---

  Future<void> _search() async {
    final username = _cleanUsername(_controller.text);
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
      _events = [];
      _currentUsername = username;
    });

    _animController.reset();

    // 1. Buscar perfil e posts (Match)
    final profile = await InstagramService.fetchProfile(username);
    List<InstagramPost> posts = [];
    if (profile != null) {
      posts = await InstagramService.fetchPosts(username);
    }

    // 2. Buscar timeline (Timeline)
    await InstagramService.trackProfile(username);
    final timelineEvents = await InstagramService.fetchTimeline(username);
    final comments = await InstagramService.fetchCommentsTimeline(username);
    final allEvents = [...timelineEvents, ...comments];
    allEvents.sort((a, b) {
      final da = a.dateTime ?? DateTime(2000);
      final db = b.dateTime ?? DateTime(2000);
      return db.compareTo(da);
    });

    // 3. Recarregar lista de monitorados
    _loadTrackedProfiles();

    // 4. Carregar logs de alteracoes
    _loadChangeLogs(username);

    if (mounted) {
      setState(() {
        _loading = false;
        _events = allEvents;
        if (profile != null) {
          _profile = InstagramProfile(
            username: profile.username,
            fullName: profile.fullName,
            biography: profile.biography,
            profilePicUrl: profile.profilePicUrl,
            followers: profile.followers,
            following: profile.following,
            posts: profile.posts,
            isPrivate: profile.isPrivate,
            isVerified: profile.isVerified,
            externalUrl: profile.externalUrl,
            recentPosts: posts.isNotEmpty ? posts : profile.recentPosts,
          );
          _animController.forward();
        } else {
          _error = 'Perfil nao encontrado ou privado';
        }
      });
    }
  }

  Future<void> _takeSnapshot() async {
    if (_currentUsername.isEmpty) return;

    setState(() => _snapshotting = true);

    final result = await InstagramService.takeSnapshot(_currentUsername);

    if (mounted) {
      setState(() => _snapshotting = false);
      if (result != null) {
        _lastSnapshotTime = DateTime.now().toString().substring(0, 19);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Snapshot salvo: ${result['followers']} seguidores, ${result['following']} seguindo'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _search(); // Atualiza tudo após snapshot
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao tirar snapshot'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Widgets da UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)))
                : _error != null
                    ? _buildError()
                    : _profile != null
                        ? _buildContent()
                        : _buildEmpty(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'INSTAGRAM MONITOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _localApiStatus ? Colors.green.withValues(alpha: 0.3) : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: _localApiStatus ? Colors.greenAccent : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      _localApiStatus ? 'API Local' : 'Publico',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (_profile != null) ...[
                const SizedBox(width: 8),
                _snapshotting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _takeSnapshot,
                        tooltip: 'Tirar Snapshot',
                      ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _search,
                  tooltip: 'Atualizar',
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Perfil + Timeline de mudancas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _search(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Digite o @ do Instagram',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE1306C)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_currentUsername.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Monitorando: @$_currentUsername',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (_lastSnapshotTime != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, color: Colors.white60, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Ultimo snapshot: $_lastSnapshotTime',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Digite um @ para monitorar', style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text('ou selecione um perfil ja cadastrado abaixo', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          if (!_localApiStatus) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  const SizedBox(height: 8),
                  const Text(
                    'Modo Limitado',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para snapshots, inicie o servidor local:\npython instagram_api/server.py',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildTrackedProfilesSection(),
        ],
      ),
    );
  }

  Widget _buildTrackedProfilesSection() {
    if (_loadingTracked) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: Color(0xFFE1306C)),
      );
    }

    if (_trackedProfiles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Nenhum perfil monitorado', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            const SizedBox(height: 4),
            Text('Pesquise um @ para comecar', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.people, size: 18, color: Color(0xFFE1306C)),
                const SizedBox(width: 8),
                Text(
                  'Perfis Monitorados (${_trackedProfiles.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF262626)),
                ),
                const Spacer(),
                Text('Job coleta a cada 1h', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._trackedProfiles.map((p) => _buildTrackedProfileTile(p)),
        ],
      ),
    );
  }

  Widget _buildTrackedProfileTile(Map<String, dynamic> profile) {
    final username = profile['username'] ?? '';
    final fullName = profile['fullName'] ?? '';
    final active = profile['active'] ?? true;
    final profileId = profile['id'] as int?;

    return InkWell(
      onTap: () {
        _controller.text = username;
        _search();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w700),
                  ),
                ),
                if (active)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@$username', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (fullName.isNotEmpty)
                    Text(fullName, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: active ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                active ? 'Ativo' : 'Inativo',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 6),
            if (profileId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red[300],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _untrackProfile(username, profileId),
                tooltip: 'Remover',
              ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Color(0xFFE1306C)),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PARTE DE CIMA: MATCH (Perfil + Stats + Posts) ---
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 16),
            if (_localApiStatus) _buildQuickActions(),
            if (_localApiStatus) const SizedBox(height: 20),
            _buildPostsSection(),
            
            // --- DIVISOR ---
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('TIMELINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // --- PARTE DE BAIXO: TIMELINE ---
            if (_events.isEmpty)
              _buildEmptyTimeline()
            else
              _buildTimelineList(),

            // --- DIVISOR LOGS ---
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('LOGS DE ALTERACOES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // --- LOGS DE ALTERACOES ---
            _buildChangeLogsSection(),
          ],
        ),
      ),
    );
  }

  // --- Widgets do Match (Perfis) ---

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)]),
                boxShadow: [BoxShadow(color: const Color(0xFFE1306C).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 42,
                  backgroundImage: _profile!.profilePicUrl.isNotEmpty ? NetworkImage(_profile!.profilePicUrl) : null,
                  child: _profile!.profilePicUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('@${_profile!.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
                if (_profile!.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Color(0xFF3897F0), size: 20),
                ],
              ],
            ),
            if (_profile!.fullName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_profile!.fullName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            _buildMonitorButton(),
            if (_profile!.biography.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Text(_profile!.biography, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF262626), height: 1.4)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Posts', InstagramService.formatCount(_profile!.posts), Icons.grid_on_rounded, const Color(0xFF833AB4)),
        _buildStatCard('Seguidores', InstagramService.formatCount(_profile!.followers), Icons.people_alt_rounded, const Color(0xFFE1306C)),
        _buildStatCard('Seguindo', InstagramService.formatCount(_profile!.following), Icons.person_add_rounded, const Color(0xFFF77737)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionChip(Icons.people, 'Ver Seguidores', const Color(0xFFE1306C), () => _showList('followers')),
        const SizedBox(width: 8),
        _buildActionChip(Icons.person_add, 'Ver Seguindo', const Color(0xFFF77737), () => _showList('following')),
      ],
    );
  }

  Widget _buildActionChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsSection() {
    final posts = _profile!.recentPosts;
    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(_profile!.isPrivate ? 'Conta privada' : 'Nenhum post encontrado', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.grid_on_rounded, size: 18, color: Color(0xFF262626)),
              const SizedBox(width: 8),
              Text('Posts recentes (${posts.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildPostCard(posts[index]),
        ),
      ],
    );
  }

  Widget _buildPostCard(InstagramPost post) {
    return GestureDetector(
      onTap: () => _showPostDetail(post),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.grey[200]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.displayUrl.isNotEmpty)
              Image.network(post.displayUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              )),
            if (post.isVideo)
              Positioned(
                top: 6, right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(Icons.videocam, color: Colors.white, size: 14),
                ),
              ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.black87, Colors.black26], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.likes), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.comments), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets da Timeline ---

  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.timeline, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Nenhum evento registrado', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Faca um snapshot para comecar a monitorar',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList() {
    final grouped = _groupByDay(_events);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return _buildDaySection(entry.key, entry.value);
      }).toList(),
    );
  }

  Map<String, List<TimelineEvent>> _groupByDay(List<TimelineEvent> events) {
    final map = <String, List<TimelineEvent>>{};
    for (final e in events) {
      final dt = e.dateTime;
      String key;
      if (dt == null) {
        key = 'Sem data';
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final eventDay = DateTime(dt.year, dt.month, dt.day);
        final diff = today.difference(eventDay).inDays;
        if (diff == 0) key = 'Hoje';
        else if (diff == 1) key = 'Ontem';
        else if (diff < 7) key = 'Ha $diff dias';
        else key = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Widget _buildDaySection(String day, List<TimelineEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFE1306C)]),
                ),
              ),
              const SizedBox(width: 10),
              Text(day, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${events.length}', style: const TextStyle(fontSize: 11, color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        ...events.map((e) => _buildEventCard(e)),
        Container(
          margin: const EdgeInsets.only(left: 4),
          width: 2,
          height: 20,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildEventCard(TimelineEvent event) {
    final color = _eventColor(event.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(event.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '@${event.username}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF262626)),
                        ),
                      ),
                      Text(event.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  if (event.fullName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(event.fullName, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.typeLabel,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (event.text != null && event.text!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        event.text!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF262626), height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (event.postId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.photo, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Post #${event.postId}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'new_follower': return const Color(0xFF4CAF50);
      case 'unfollowed': return const Color(0xFFF44336);
      case 'you_followed': return const Color(0xFF2196F3);
      case 'unfollowed_by_you': return const Color(0xFFFF9800);
      case 'liked_post': return const Color(0xFFE91E63);
      case 'unliked_post': return const Color(0xFF9C27B0);
      case 'comment': return const Color(0xFF00BCD4);
      default: return const Color(0xFF607D8B);
    }
  }

  // --- Modais (Listas e Detalhes) ---

  Future<void> _showList(String type) async {
    if (_profile == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  type == 'followers' ? 'Seguidores' : 'Seguindo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<InstagramLiker>>(
                  future: type == 'followers'
                      ? InstagramService.fetchFollowers(_profile!.username)
                      : InstagramService.fetchFollowing(_profile!.username),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)));
                    }
                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Servidor local indisponivel', style: TextStyle(color: Colors.grey)),
                            Text('Inicie: python instagram_api/server.py', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    final list = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final user = list[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                            child: Text(user.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
                          ),
                          title: Text('@${user.username}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: user.fullName.isNotEmpty ? Text(user.fullName, style: const TextStyle(fontSize: 12)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed: () {},
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostDetail(InstagramPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (post.displayUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(post.displayUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 50)),
                        )),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDetailStat(Icons.favorite, '${post.likes} curtidas', const Color(0xFFE1306C)),
                        const SizedBox(width: 20),
                        _buildDetailStat(Icons.chat_bubble, '${post.comments} comentarios', const Color(0xFF3897F0)),
                      ],
                    ),
                    if (post.timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(post.timeAgo, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                    if (post.caption != null && post.caption!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(post.caption!, style: const TextStyle(fontSize: 13, height: 1.5)),
                    ],
                    if (_localApiStatus) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildLikersSection(post),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikersSection(InstagramPost post) {
    return FutureBuilder<List<InstagramLiker>>(
      future: InstagramService.fetchLikers(post.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE1306C))),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final likers = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 18, color: Color(0xFFE1306C)),
                const SizedBox(width: 8),
                Text('Quem curtiu (${likers.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: likers.map((l) => Chip(
                avatar: CircleAvatar(
                  backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  child: Text(l.username[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFFE1306C))),
                ),
                label: Text('@${l.username}', style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey[100],
              )).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMonitorButton() {
    final tracked = _isProfileTracked(_currentUsername);
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton.icon(
          onPressed: tracked
              ? null
              : () async {
                  final success = await InstagramService.trackProfile(_currentUsername);
                  if (success) {
                    await _loadTrackedProfiles();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('@$_currentUsername adicionado ao monitoramento'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    }
                  }
                },
          icon: Icon(
            tracked ? Icons.check_circle_outline : Icons.visibility,
            size: 18,
          ),
          label: Text(
            tracked ? 'Monitorando' : 'Monitorar',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: tracked ? Colors.grey[200] : const Color(0xFF4CAF50),
            foregroundColor: tracked ? Colors.grey[600] : Colors.white,
            disabledBackgroundColor: Colors.grey[200],
            disabledForegroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: tracked ? 0 : 3,
          ),
        ),
      ),
    );
  }

  Widget _buildChangeLogsSection() {
    if (_loadingLogs) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE1306C))),
      );
    }

    if (_changeLogs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Nenhuma alteracao registrada', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text('Os logs apareceram quando o job detectar mudancas', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Color(0xFF833AB4)),
                const SizedBox(width: 8),
                Text('Ultimas alteracoes (${_changeLogs.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._changeLogs.map((log) => _buildChangeLogItem(log)),
        ],
      ),
    );
  }

  Widget _buildChangeLogItem(Map<String, dynamic> log) {
    final type = (log['changeType'] ?? '') as String;
    final desc = (log['description'] ?? '') as String;
    final oldVal = (log['oldValue'] ?? '') as String;
    final newVal = (log['newValue'] ?? '') as String;
    final createdAt = (log['createdAt'] ?? '') as String;

    IconData icon;
    Color color;
    switch (type) {
      case 'followers_count':
        icon = Icons.people;
        color = const Color(0xFFE1306C);
        break;
      case 'following_count':
        icon = Icons.person_add;
        color = const Color(0xFF833AB4);
        break;
      case 'posts_count':
        icon = Icons.photo_library;
        color = const Color(0xFFF77737);
        break;
      case 'post_likes':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'post_comments':
        icon = Icons.comment;
        color = const Color(0xFF405DE6);
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateStr = createdAt;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (oldVal.isNotEmpty) ...[
                      Text(oldVal, style: TextStyle(fontSize: 11, color: Colors.grey[600], decoration: TextDecoration.lineThrough)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                      ),
                    ],
                    if (newVal.isNotEmpty)
                      Text(newVal, style: TextStyle(fontSize: 11, color: Colors.grey[800], fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
