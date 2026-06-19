import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../../services/instagram_service.dart';
import '../../utils/api_links.dart';

class InstagramMonitorScreen extends StatefulWidget {
  const InstagramMonitorScreen({super.key});

  @override
  State<InstagramMonitorScreen> createState() => _InstagramMonitorScreenState();
}

class _InstagramMonitorScreenState extends State<InstagramMonitorScreen> with TickerProviderStateMixin {
  // Controladores e estado do Match
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  InstagramProfile? _profile;
  bool _loading = false;
  String? _error;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  bool _localApiStatus = false;

  // Estado da Timeline
  List<TimelineEvent> _events = [];
  String _currentUsername = '';
  TimelineEvent? _eventoSelecionado;

  // Controle de lazy loading por aba
  bool _timelineCarregada = false;
  bool _logsCarregados = false;
  bool _dashboardCarregado = false;

  // Perfis monitorados
  List<Map<String, dynamic>> _trackedProfiles = [];
  bool _loadingTracked = false;

  // Logs de alteracoes
  List<Map<String, dynamic>> _changeLogs = [];
  bool _loadingLogs = false;

  // Novos estados para chips e monitoramento
  String? _selectedChipUsername;
  bool _showMonitorButtons = false;

  // Filtros por tipo de evento
  String? _filtroLog;
  String? _filtroTimeline;

  // Paginação da timeline
  int _timelinePagina = 0;
  bool _timelineTemMais = false;
  bool _carregandoMais = false;
  int _timelineTotal = 0;

  // Dashboard
  bool _dashLoading = false;
  int _dashSeguidores = 0;
  int _dashSeguindo = 0;
  int _dashMutuos = 0;
  int _dashSigoNaoMeSegue = 0;
  int _dashMeSegueNaoSigo = 0;
  List<Map<String, dynamic>> _dashSerie = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _currentUsername.isEmpty) return;
      switch (_tabController.index) {
        case 1:
          if (!_timelineCarregada) _carregarTimeline(_currentUsername);
          break;
        case 2:
          if (!_logsCarregados) _loadChangeLogs(_currentUsername);
          break;
        case 3:
          if (!_dashboardCarregado) _loadDashboard(_currentUsername);
          break;
      }
    });
    _checkLocalApi();
    _loadTrackedProfiles();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkLocalApi() async {
    await InstagramService.checkLocalApi();
    if (mounted) setState(() => _localApiStatus = InstagramService.hasLocalApi);
  }

  Future<void> _reconectarApi() async {
    if (mounted) setState(() => _localApiStatus = false);
    await InstagramService.checkLocalApi();
    if (!mounted) return;
    final conectou = InstagramService.hasLocalApi;
    setState(() => _localApiStatus = conectou);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(conectou ? 'API reconectada com sucesso' : 'API offline — verifique se o servidor está rodando'),
      backgroundColor: conectou ? Colors.green.shade700 : Colors.red.shade700,
      duration: const Duration(seconds: 3),
    ));
  }

  /// Extrai e valida username de URL, @user ou username puro. Retorna null se inválido.
  String? _cleanUsername(String input) {
    var clean = input.trim();
    clean = clean.replaceAll(RegExp(r'https?://(www\.)?instagram\.com/'), '');
    clean = clean.replaceAll(RegExp(r'/+$'), '');
    clean = clean.replaceAll('@', '');
    clean = clean.split('?').first.trim();
    if (clean.isEmpty || !RegExp(r'^[a-zA-Z0-9._]{1,30}$').hasMatch(clean)) return null;
    return clean;
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
          // Se o perfil removido era o selecionado no chip, limpa selecao
          if (_selectedChipUsername == username) {
            _selectedChipUsername = null;
            _profile = null;
            _events = [];
            _changeLogs = [];
            _currentUsername = '';
          }
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
    if (_logsCarregados) return;
    setState(() => _loadingLogs = true);
    final logs = await InstagramService.fetchChangeLogs(username);
    if (mounted) {
      setState(() {
        _changeLogs = logs;
        _loadingLogs = false;
        _logsCarregados = true;
      });
    }
  }

  Future<void> _loadDashboard(String username) async {
    if (_dashboardCarregado) return;
    setState(() => _dashLoading = true);
    final d = await InstagramService.fetchDashboard(username);
    if (mounted) {
      setState(() {
        _dashSeguidores = (d['seguidores'] as num?)?.toInt() ?? 0;
        _dashSeguindo = (d['seguindo'] as num?)?.toInt() ?? 0;
        _dashMutuos = (d['mutuos'] as num?)?.toInt() ?? 0;
        _dashSigoNaoMeSegue = (d['sigoNaoMeSegue'] as num?)?.toInt() ?? 0;
        _dashMeSegueNaoSigo = (d['meSegueNaoSigo'] as num?)?.toInt() ?? 0;
        _dashSerie = ((d['serie'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _dashLoading = false;
        _dashboardCarregado = true;
      });
    }
  }

  Future<void> _carregarMaisTimeline() async {
    if (_carregandoMais || !_timelineTemMais || _currentUsername.isEmpty) return;
    setState(() => _carregandoMais = true);
    final proxPagina = _timelinePagina + 1;
    final resp = await InstagramService.fetchTimelinePaginado(
        _currentUsername, page: proxPagina, size: 100);
    final novos = (resp['events'] as List<TimelineEvent>);
    if (mounted) {
      setState(() {
        _events = [..._events, ...novos];
        _timelinePagina = proxPagina;
        _timelineTemMais = resp['hasMore'] as bool;
        _carregandoMais = false;
      });
    }
  }

  // --- Acoes de busca e snapshot ---

  /// Carrega apenas perfil e posts (aba 0). As demais abas carregam sob demanda.
  Future<void> _loadProfileData(String username) async {
    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
      _events = [];
      _changeLogs = [];
      _currentUsername = username;
      _timelineCarregada = false;
      _logsCarregados = false;
      _dashboardCarregado = false;
      _eventoSelecionado = null;
    });

    _animController.reset();

    InstagramProfile? profile;
    String? erroFetch;
    try {
      profile = await InstagramService.fetchProfile(username);
    } on InstagramException catch (e) {
      erroFetch = e.mensagem;
    } catch (_) {}

    List<InstagramPost> posts = [];
    if (profile != null) {
      posts = await InstagramService.fetchPostsFromDb(username);
    }

    if (mounted) {
      setState(() {
        _loading = false;
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
            recentPosts: posts,
          );
          _animController.forward();
          _showMonitorButtons = !_isProfileTracked(username);
        } else {
          _error = erroFetch ?? 'Perfil nao encontrado ou privado';
        }
      });
    }
  }

  /// Carrega a timeline ao abrir a aba 1 (lazy).
  Future<void> _carregarTimeline(String username) async {
    if (_timelineCarregada) return;
    final timelineResp = await InstagramService.fetchTimelinePaginado(username, page: 0, size: 100);
    final allEvents = (timelineResp['events'] as List<TimelineEvent>);
    allEvents.sort((a, b) {
      final da = a.dateTime ?? DateTime(2000);
      final db = b.dateTime ?? DateTime(2000);
      return db.compareTo(da);
    });
    if (mounted) {
      setState(() {
        _events = allEvents;
        _timelinePagina = 0;
        _timelineTotal = (timelineResp['total'] as num).toInt();
        _timelineTemMais = timelineResp['hasMore'] as bool;
        _timelineCarregada = true;
      });
    }
  }

  /// Acao de busca a partir do input: limpa username, mostra botoes, carrega dados
  Future<void> _onSearch() async {
    final username = _cleanUsername(_controller.text);
    if (username == null) {
      setState(() => _error = 'Username invalido. Use @nome ou instagram.com/nome');
      return;
    }

    // Atualiza o chip selecionado
    setState(() {
      _selectedChipUsername = username;
    });

    await _loadProfileData(username);

    // Mostra botoes de monitoramento se ainda nao esta tracked
    if (mounted) {
      setState(() {
        _showMonitorButtons = !_isProfileTracked(username);
      });
    }
  }

  Future<void> _mostrarPainelJobs() async {
    await showDialog(
      context: context,
      builder: (_) => _PainelJobsDialog(
        username: _currentUsername.isNotEmpty ? _currentUsername : null,
      ),
    );
  }

  Future<void> _abrirConfigSessoes() async {
    await showDialog(
      context: context,
      builder: (_) => const _ConfigSessoesDialog(),
    );
  }


  // --- Painel de perfis monitorados (20% da altura, scroll horizontal) ---

  Widget _buildPainelMonitorados(double alturaPanel) {
    return Container(
      height: alturaPanel,
      color: const Color(0xFFF5F5F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_outlined, size: 14, color: Color(0xFFE1306C)),
                const SizedBox(width: 6),
                Text(
                  'Monitorados (${_trackedProfiles.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF262626)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    _focusNode.requestFocus();
                    setState(() {
                      _selectedChipUsername = null;
                      _showMonitorButtons = false;
                      _profile = null;
                      _events = [];
                      _changeLogs = [];
                      _currentUsername = '';
                      _error = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1306C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1306C).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 13, color: Color(0xFFE1306C)),
                        SizedBox(width: 3),
                        Text('Adicionar', style: TextStyle(fontSize: 11, color: Color(0xFFE1306C), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingTracked && _trackedProfiles.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C), strokeWidth: 2))
                : _trackedProfiles.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum perfil monitorado. Busque e clique "Monitorar".',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        itemCount: _trackedProfiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => _buildCartaoPerfil(_trackedProfiles[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartaoPerfil(Map<String, dynamic> profile) {
    final username = profile['username'] as String? ?? '';
    final fullName = profile['fullName'] as String? ?? '';
    final profilePicUrl = profile['profilePicUrl'] as String? ?? '';
    final profileId = profile['id'] as int?;
    final changeCount = (profile['changeCount'] as num?)?.toInt() ?? 0;
    final isSelected = _selectedChipUsername == username;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChipUsername = username;
          _showMonitorButtons = false;
        });
        _controller.text = username;
        _loadProfileData(username);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF833AB4).withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFE1306C) : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFE1306C).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.15),
                    child: profilePicUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              ApiLinks.imageProxy(profilePicUrl),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ),
                          )
                        : Text(
                            username.isNotEmpty ? username[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                  ),
                  if (changeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1306C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          changeCount > 99 ? '99+' : '$changeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '@$username',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFFE1306C) : const Color(0xFF262626),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (fullName.isNotEmpty)
                Text(
                  fullName,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              if (profileId != null)
                GestureDetector(
                  onTap: () => _untrackProfile(username, profileId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 10, color: Colors.red),
                        SizedBox(width: 2),
                        Text('Parar', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets da UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F8),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final alturaPanel = constraints.maxHeight * 0.20;
            return Column(
              children: [
                _buildHeader(),
                _buildPainelMonitorados(alturaPanel),
                _buildSearchInput(),
                if (_profile != null) _buildTabBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)))
                      : _error != null
                          ? _buildError()
                          : _profile != null
                              ? _buildTabContent()
                              : _buildEmpty(),
                ),
              ],
            );
          },
        ),
    );
  }

  // ====================== ABA DASHBOARD ======================

  // Paleta da tela (mantem consistencia com as outras abas)
  static const Color _rosaInstagram = Color(0xFFE1306C);
  static const Color _roxoInstagram = Color(0xFF833AB4);

  // Abre um modal com a lista de usuarios de uma relacao do dashboard.
  void _showRelacao(String tipo, String titulo, Color cor) {
    if (_profile == null) return;
    final username = _profile!.username;
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: FutureBuilder<List<InstagramLiker>>(
                  future: InstagramService.fetchRelacaoDashboard(username, tipo),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: cor));
                    }
                    final lista = snap.data ?? [];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.people_outline, size: 20, color: cor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('$titulo (${lista.length})',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: lista.isEmpty
                              ? const Center(child: Text('Nenhum usuario nesta categoria', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: lista.length,
                                  itemBuilder: (context, i) {
                                    final u = lista[i];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: cor.withValues(alpha: 0.12),
                                        child: Text(
                                          u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                          style: TextStyle(color: cor, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      title: Text('@${u.username}'),
                                      subtitle: u.fullName.isNotEmpty ? Text(u.fullName) : null,
                                    );
                                  },
                                ),
                        ),
                      ],
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

  Future<void> _showDialogImportManual(String tipo, String rotulo, Color cor) async {
    if (_currentUsername.isEmpty) return;
    final ctrl = TextEditingController();
    bool enviando = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_outlined, color: cor, size: 20),
              const SizedBox(width: 8),
              Text('Importar $rotulo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cole os usernames abaixo, um por linha.\nO @ no inicio é opcional.',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    hintText: 'joao_silva\n@maria123\npedro.dev',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: enviando ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: enviando
                  ? null
                  : () async {
                      final linhas = ctrl.text
                          .split('\n')
                          .map((l) => l.trim().replaceAll('@', ''))
                          .where((l) => l.isNotEmpty)
                          .toList();
                      if (linhas.isEmpty) return;
                      setStateDlg(() => enviando = true);
                      final resultado = await InstagramService.importarManual(
                          _currentUsername, tipo, linhas);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (resultado != null) {
                        final inseridos = resultado['inseridos'] ?? 0;
                        final ignorados = resultado['duplicatasIgnoradas'] ?? 0;
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('$inseridos inseridos, $ignorados ignorados (duplicatas)'),
                            backgroundColor: Colors.green.shade700,
                          ));
                          if (inseridos > 0) _loadDashboard(_currentUsername);
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Erro ao importar. Verifique o backend.'),
                            backgroundColor: Colors.red.shade700,
                          ));
                        }
                      }
                    },
              icon: enviando
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload, size: 16),
              label: Text(enviando ? 'Importando...' : 'Importar'),
              style: ElevatedButton.styleFrom(backgroundColor: cor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  Widget _buildDashboardTab() {
    if (_dashLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _rosaInstagram),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 16),
          _buildEvolutionCard(),
        ],
      ),
    );
  }

  // Grid responsivo de metricas. Usa Wrap para nao estourar em telas estreitas.
  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double espacamento = 12;
        final int colunas = constraints.maxWidth < 360 ? 2 : 3;
        final double larguraCard =
            (constraints.maxWidth - espacamento * (colunas - 1)) / colunas;

        final List<Widget> cards = [
          _buildMetricCard(
            valor: _dashMutuos,
            rotulo: 'Mutuos',
            icone: Icons.handshake_outlined,
            cor: const Color(0xFF2E7D32),
            largura: larguraCard,
            relacaoTipo: 'mutuos',
          ),
          _buildMetricCard(
            valor: _dashSigoNaoMeSegue,
            rotulo: 'Eu sigo / nao me seguem',
            icone: Icons.person_remove_outlined,
            cor: const Color(0xFFEF6C00),
            largura: larguraCard,
            relacaoTipo: 'sigo_nao_me_segue',
          ),
          _buildMetricCard(
            valor: _dashMeSegueNaoSigo,
            rotulo: 'Me seguem / nao sigo',
            icone: Icons.person_add_alt_1_outlined,
            cor: const Color(0xFF1565C0),
            largura: larguraCard,
            relacaoTipo: 'me_segue_nao_sigo',
          ),
          _buildMetricCard(
            valor: _dashSeguidores,
            rotulo: 'Seguidores',
            icone: Icons.group_outlined,
            cor: _rosaInstagram,
            largura: larguraCard,
            tipoImport: 'followers',
          ),
          _buildMetricCard(
            valor: _dashSeguindo,
            rotulo: 'Seguindo',
            icone: Icons.how_to_reg_outlined,
            cor: _roxoInstagram,
            tipoImport: 'following',
            largura: larguraCard,
          ),
        ];

        return Wrap(
          spacing: espacamento,
          runSpacing: espacamento,
          children: cards,
        );
      },
    );
  }

  Widget _buildMetricCard({
    required int valor,
    required String rotulo,
    required IconData icone,
    required Color cor,
    required double largura,
    String? relacaoTipo,
    String? tipoImport,
  }) {
    return Container(
      width: largura,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, size: 18, color: cor),
              ),
              const Spacer(),
              if (relacaoTipo != null)
                InkWell(
                  onTap: () => _showRelacao(relacaoTipo, rotulo, cor),
                  borderRadius: BorderRadius.circular(20),
                  child: Tooltip(
                    message: 'Ver lista',
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.visibility_outlined, size: 18, color: cor),
                    ),
                  ),
                ),
              if (tipoImport != null)
                InkWell(
                  onTap: () => _showDialogImportManual(tipoImport, rotulo, cor),
                  borderRadius: BorderRadius.circular(20),
                  child: Tooltip(
                    message: 'Importar manualmente',
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.upload_outlined, size: 18, color: cor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$valor',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            rotulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.show_chart, size: 18, color: _rosaInstagram),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Evolucao (seguidores x seguindo)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_dashSerie.length < 2)
            _buildChartEmptyState()
          else ...[
            _buildLegenda(),
            const SizedBox(height: 12),
            SizedBox(height: 220, child: _buildEvolutionChart()),
          ],
        ],
      ),
    );
  }

  Widget _buildLegenda() {
    return Row(
      children: [
        _legendaItem(_rosaInstagram, 'Seguidores'),
        const SizedBox(width: 16),
        _legendaItem(_roxoInstagram, 'Seguindo'),
      ],
    );
  }

  Widget _legendaItem(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildChartEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: const [
          Icon(Icons.timeline, size: 40, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Sem historico suficiente ainda — os pontos aparecem '
            'conforme o job coleta dia a dia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart() {
    final List<FlSpot> pontosSeguidores = [];
    final List<FlSpot> pontosSeguindo = [];
    double maxY = 0;

    for (int i = 0; i < _dashSerie.length; i++) {
      final item = _dashSerie[i];
      final double followers = (item['followers'] as num?)?.toDouble() ?? 0;
      final double following = (item['following'] as num?)?.toDouble() ?? 0;
      pontosSeguidores.add(FlSpot(i.toDouble(), followers));
      pontosSeguindo.add(FlSpot(i.toDouble(), following));
      if (followers > maxY) maxY = followers;
      if (following > maxY) maxY = following;
    }

    final double topo = maxY <= 0 ? 10 : maxY * 1.1;
    final double intervaloY = topo / 4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_dashSerie.length - 1).toDouble(),
        minY: 0,
        maxY: topo,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervaloY <= 0 ? 1 : intervaloY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: intervaloY <= 0 ? 1 : intervaloY,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: Colors.black45),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int indice = value.toInt();
                if (indice < 0 || indice >= _dashSerie.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatarDataEixo(_dashSerie[indice]['data']?.toString()),
                    style: const TextStyle(fontSize: 9, color: Colors.black45),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          _linhaGrafico(pontosSeguidores, _rosaInstagram),
          _linhaGrafico(pontosSeguindo, _roxoInstagram),
        ],
      ),
    );
  }

  LineChartBarData _linhaGrafico(List<FlSpot> pontos, Color cor) {
    return LineChartBarData(
      spots: pontos,
      isCurved: true,
      color: cor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: cor.withValues(alpha: 0.08),
      ),
    );
  }

  // Converte '2026-06-15' em '15/06' para caber no eixo X.
  String _formatarDataEixo(String? data) {
    if (data == null || data.isEmpty) return '';
    final partes = data.split('-');
    if (partes.length != 3) return data;
    return '${partes[2]}/${partes[1]}';
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFE1306C),
        labelColor: const Color(0xFFE1306C),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Perfil'),
          Tab(icon: Icon(Icons.timeline, size: 18), text: 'Timeline'),
          Tab(icon: Icon(Icons.receipt_long, size: 18), text: 'Logs'),
          Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Dashboard'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                if (_localApiStatus) _buildQuickActions(),
                if (_localApiStatus) const SizedBox(height: 20),
                _buildPostsSection(),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildTimelineGrafico(),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildChangeLogsSection(),
          ),
          _buildDashboardTab(),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: (_) => _onSearch(),
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: '@usuario ou link do Instagram',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: IconButton(
                icon: const Icon(Icons.search, color: Color(0xFFE1306C)),
                onPressed: _onSearch,
              ),
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
              Flexible(
                child: Text(
                  'INSTAGRAM MONITOR',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _reconectarApi,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _localApiStatus ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: _localApiStatus ? null : Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: _localApiStatus ? Colors.greenAccent : Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        _localApiStatus ? 'API Local' : 'Offline',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      if (!_localApiStatus) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.refresh, size: 12, color: Colors.orange),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.analytics, color: Colors.white),
                onPressed: _mostrarPainelJobs,
                tooltip: 'Status dos jobs e interações',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _abrirConfigSessoes,
                tooltip: 'Configurar sessões do Instagram',
              ),
              if (_profile != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _loadProfileData(_currentUsername),
                  tooltip: 'Atualizar',
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Perfil + Timeline de mudancas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
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
          Text('Monitore um perfil do Instagram', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Cole um link ou @username no campo acima', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _focusNode.requestFocus(),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Buscar perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
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
        ],
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
            onPressed: _onSearch,
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
                  backgroundColor: Colors.grey[100],
                  child: _profile!.profilePicUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            ApiLinks.imageProxy(_profile!.profilePicUrl),
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.grey),
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

            // Botao de monitoramento condicional
            _buildMonitorButtons(),

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

  /// Botao de monitoramento: mostra "Monitorando" badge ou botoes "Apenas Ver" / "Monitorar"
  Widget _buildMonitorButtons() {
    final tracked = _isProfileTracked(_currentUsername);

    // Perfil ja monitorado: mostra badge
    if (tracked || !_showMonitorButtons) {
      if (tracked) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                'Monitorando',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Botoes "Apenas Ver" e "Monitorar"
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              // Apenas visualiza, nao trackeia
              setState(() => _showMonitorButtons = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('@$_currentUsername esta em modo visualizacao'),
                    backgroundColor: Colors.grey.shade700,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Apenas Ver', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF833AB4),
              side: const BorderSide(color: Color(0xFF833AB4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final success = await InstagramService.trackProfile(
                _currentUsername,
                fullName: _profile?.fullName ?? '',
                profilePicUrl: _profile?.profilePicUrl ?? '',
              );
              if (!mounted) return;
              if (success) {
                await _loadTrackedProfiles();
                if (mounted) {
                  setState(() {
                    _showMonitorButtons = false;
                    _selectedChipUsername = _currentUsername;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('@$_currentUsername adicionado ao monitoramento'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Falha ao monitorar @$_currentUsername. Verifique se você está logado e se o backend está no ar.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            icon: const Icon(Icons.monitor_heart_outlined, size: 18),
            label: const Text('Monitorar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
          ),
        ),
      ],
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4),
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
            if (post.imageUrl.isNotEmpty)
              Image.network(post.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.black87, Colors.black26], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.likes), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(InstagramService.formatCount(post.comments), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
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
          Text(
            'Nenhum evento registrado',
            style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Os jobs coletam dados automaticamente a cada 6 horas',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarApagarTimeline() async {
    if (_currentUsername.isEmpty) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar timeline'),
        content: Text('Apagar todos os eventos da timeline de @$_currentUsername? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final ok = await InstagramService.limparTimeline(_currentUsername);
    if (!mounted) return;
    if (ok) {
      setState(() { _events = []; _timelineTemMais = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeline apagada com sucesso.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar timeline.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmarApagarLogs() async {
    if (_currentUsername.isEmpty) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar logs'),
        content: Text('Apagar todos os logs de @$_currentUsername? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final ok = await InstagramService.limparChangeLogs(_currentUsername);
    if (!mounted) return;
    if (ok) {
      setState(() { _changeLogs = []; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs apagados com sucesso.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar logs.'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Gráfico de Timeline Horizontal ---

  Widget _buildTimelineGrafico() {
    final eventosFiltrados = _filtroTimeline == null
        ? _events
        : _events.where((e) => e.type == _filtroTimeline).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFiltrosChips(
                _filtroTimeline,
                (v) => setState(() {
                  _filtroTimeline = v;
                  _eventoSelecionado = null;
                }),
              ),
            ),
            TextButton.icon(
              onPressed: _confirmarApagarTimeline,
              icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
              label: const Text('Apagar', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (eventosFiltrados.isEmpty)
          _buildEmptyTimeline()
        else ...[
          _buildGraficoHorizontal(eventosFiltrados),
          if (_eventoSelecionado != null) _buildDetalheEvento(_eventoSelecionado!),
        ],
        _buildBotaoCarregarMais(),
      ],
    );
  }

  Widget _buildGraficoHorizontal(List<TimelineEvent> eventos) {
    final Map<String, List<TimelineEvent>> porDia = {};
    for (final e in eventos) {
      final dt = e.dateTime;
      if (dt == null) continue;
      final chave = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      porDia.putIfAbsent(chave, () => []).add(e);
    }

    final diasOrdenados = porDia.keys.toList()
      ..sort((a, b) {
        final pa = a.split('/');
        final pb = b.split('/');
        final mA = int.tryParse(pa[1]) ?? 0;
        final dA = int.tryParse(pa[0]) ?? 0;
        final mB = int.tryParse(pb[1]) ?? 0;
        final dB = int.tryParse(pb[0]) ?? 0;
        if (mA != mB) return mA.compareTo(mB);
        return dA.compareTo(dB);
      });

    final hoje = DateTime.now();
    final hojeChave =
        '${hoje.day.toString().padLeft(2, '0')}/${hoje.month.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: diasOrdenados
              .map((dia) => _buildColunaEvento(dia, porDia[dia]!, dia == hojeChave))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildColunaEvento(String dia, List<TimelineEvent> eventos, bool eHoje) {
    const largura = 148.0;
    return SizedBox(
      width: largura,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...eventos.map((e) => _buildChipEvento(e)),
          const SizedBox(height: 8),
          // Eixo horizontal
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 2,
                color: eHoje ? const Color(0xFF4FC3F7) : const Color(0xFFDDDDDD),
              ),
              Positioned(
                left: largura / 2 - 1,
                top: -3,
                child: Container(
                  width: 2,
                  height: 8,
                  color: eHoje ? const Color(0xFF4FC3F7) : const Color(0xFFAAAAAA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Column(
              children: [
                Text(
                  dia,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: eHoje ? FontWeight.w700 : FontWeight.normal,
                    color: eHoje ? const Color(0xFF4FC3F7) : const Color(0xFF888888),
                  ),
                ),
                if (eHoje)
                  Text(
                    'hoje',
                    style: TextStyle(
                      fontSize: 9,
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipEvento(TimelineEvent evento) {
    final cor = _eventColor(evento.type);
    final selecionado = _eventoSelecionado == evento;
    return GestureDetector(
      onTap: () => setState(
          () => _eventoSelecionado = selecionado ? null : evento),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: selecionado
              ? cor.withValues(alpha: 0.22)
              : cor.withValues(alpha: 0.09),
          border: Border.all(
              color: cor.withValues(alpha: selecionado ? 0.8 : 0.35)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              child: Center(
                  child: Text(evento.emoji,
                      style: const TextStyle(fontSize: 9))),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '@${evento.username}',
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalheEvento(TimelineEvent evento) {
    final cor = _eventColor(evento.type);
    final label = _eventTypeLabel(evento.type);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: cor, width: 3)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Text(evento.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: cor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    if (evento.dateTime != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${evento.dateTime!.day.toString().padLeft(2, '0')}/${evento.dateTime!.month.toString().padLeft(2, '0')} às ${evento.dateTime!.hour.toString().padLeft(2, '0')}:${evento.dateTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('@${evento.username}',
                    style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                if (evento.fullName.isNotEmpty &&
                    evento.fullName != evento.username)
                  Text(evento.fullName,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                if (evento.text != null && evento.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"${evento.text}"',
                      style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _eventTypeLabel(String type) {
    switch (type) {
      case 'new_follower': return 'Novo seguidor';
      case 'unfollowed': return 'Deixou de seguir';
      case 'you_followed': return 'Você seguiu';
      case 'unfollowed_by_you': return 'Você deixou de seguir';
      case 'liked_post': return 'Curtiu post';
      case 'unliked_post': return 'Descurtiu post';
      case 'comment': return 'Comentário';
      default: return type;
    }
  }

  // placeholder para manter compatibilidade com código legado que ainda usa _buildEventCard
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
                child: _ModalListaUsuarios(
                  username: _profile!.username,
                  tipo: type,
                  scrollController: scrollController,
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
                    if (post.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(post.imageUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(
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
    // Likers não disponíveis sem API Python — seção desativada
    return const SizedBox.shrink();
    return FutureBuilder<List<InstagramLiker>>(
      future: Future.value([]),
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

  Widget _buildBotaoCarregarMais() {
    if (!_timelineTemMais && !_carregandoMais) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _carregandoMais
            ? const CircularProgressIndicator(color: Color(0xFFE1306C), strokeWidth: 2)
            : OutlinedButton.icon(
                onPressed: _carregarMaisTimeline,
                icon: const Icon(Icons.expand_more, size: 18),
                label: Text('Carregar mais (${_events.length} de $_timelineTotal)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE1306C),
                  side: const BorderSide(color: Color(0xFFE1306C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
      ),
    );
  }

  static final List<MapEntry<String, String?>> _filtrosDisponiveis = [
    const MapEntry('Todos', null),
    const MapEntry('Começou a seguir', 'new_follower'),
    const MapEntry('Deixou de seguir', 'unfollowed'),
    const MapEntry('Você seguiu', 'you_followed'),
    const MapEntry('Você deixou de seguir', 'unfollowed_by_you'),
    const MapEntry('Curtidas', 'liked_post'),
    const MapEntry('Comentários', 'comment'),
  ];

  Widget _buildFiltrosChips(String? filtroAtivo, void Function(String?) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: _filtrosDisponiveis.map((par) {
          final label = par.key;
          final value = par.value;
          final selecionado = filtroAtivo == value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label, style: TextStyle(
                fontSize: 12,
                color: selecionado ? Colors.white : const Color(0xFF262626),
                fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
              )),
              selected: selecionado,
              onSelected: (_) => onSelect(selecionado ? null : value),
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFFE1306C),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(
                color: selecionado ? const Color(0xFFE1306C) : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
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
            Icon(Icons.history_toggle_off, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Nenhum log registrado', style: TextStyle(color: Colors.grey, fontSize: 13)),
            Text('Os logs aparecem quando o job detectar mudancas no perfil', style: TextStyle(color: Colors.grey, fontSize: 11)),
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
                Text('Historico de mudancas (${_changeLogs.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _confirmarApagarLogs(),
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
                  label: const Text('Apagar logs', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._changeLogs.map((log) => _buildChangeLogEntry(log)),
        ],
      ),
    );
  }

  Widget _buildChangeLogEntry(Map<String, dynamic> log) {
    final changeType = (log['changeType'] as String? ?? '').toLowerCase();
    final description = log['description'] as String? ?? '';
    final oldValue = log['oldValue'] as String? ?? '';
    final newValue = log['newValue'] as String? ?? '';
    final createdAt = log['createdAt'] as String? ?? '';

    IconData icon;
    Color color;

    if (changeType.contains('followers')) {
      final diff = int.tryParse(newValue) != null && int.tryParse(oldValue) != null
          ? (int.parse(newValue) - int.parse(oldValue))
          : 0;
      icon = diff >= 0 ? Icons.group_add : Icons.group_remove;
      color = diff >= 0 ? const Color(0xFFE1306C) : Colors.grey;
    } else if (changeType.contains('following')) {
      final diff = int.tryParse(newValue) != null && int.tryParse(oldValue) != null
          ? (int.parse(newValue) - int.parse(oldValue))
          : 0;
      icon = diff >= 0 ? Icons.person_add : Icons.person_off;
      color = diff >= 0 ? const Color(0xFF833AB4) : Colors.blueGrey;
    } else if (changeType.contains('posts')) {
      icon = Icons.photo_library_outlined;
      color = const Color(0xFFF77737);
    } else if (changeType.contains('bio')) {
      icon = Icons.edit_note;
      color = const Color(0xFF405DE6);
    } else {
      icon = Icons.info_outline;
      color = Colors.grey;
    }

    String dateStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                if (oldValue.isNotEmpty && newValue.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '$oldValue → $newValue',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
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

/// Widget dedicado para o modal de seguidores/seguindo.
/// Mantém o Future fixo no initState para evitar recriar requisições a cada rebuild do DraggableScrollableSheet.
class _ModalListaUsuarios extends StatefulWidget {
  final String username;
  final String tipo;
  final ScrollController scrollController;

  const _ModalListaUsuarios({
    required this.username,
    required this.tipo,
    required this.scrollController,
  });

  @override
  State<_ModalListaUsuarios> createState() => _ModalListaUsuariosState();
}

class _ModalListaUsuariosState extends State<_ModalListaUsuarios> {
  late final Future<List<InstagramLiker>> _futuroUsuarios;

  @override
  void initState() {
    super.initState();
    _futuroUsuarios = widget.tipo == 'followers'
        ? InstagramService.fetchFollowersFromDb(widget.username)
        : InstagramService.fetchFollowingFromDb(widget.username);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InstagramLiker>>(
      future: _futuroUsuarios,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFE1306C)),
                const SizedBox(height: 16),
                Text(
                  'Buscando todos os ${widget.tipo == 'followers' ? 'seguidores' : 'seguindo'}...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 40, color: Colors.orange[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'Nao foi possivel carregar a lista',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O Instagram pode estar bloqueando temporariamente a sessao (soft-block).\n'
                    'Os dados de seguidores/seguidos exigem autenticacao privada.\n'
                    'Aguarde alguns minutos e tente novamente.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final usuarios = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${usuarios.length} ${widget.tipo == 'followers' ? 'seguidores' : 'seguindo'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar todos', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE1306C)),
                    onPressed: () {
                      final texto = usuarios
                          .map((u) => u.fullName.isNotEmpty
                              ? '@${u.username} - ${u.fullName}'
                              : '@${u.username}')
                          .join('\n');
                      Clipboard.setData(ClipboardData(text: texto));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${usuarios.length} usuários copiados para a área de transferência'),
                          backgroundColor: Colors.green.shade700,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final user = usuarios[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE1306C).withValues(alpha: 0.1),
                      child: Text(user.username[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
                    ),
                    title: Text('@${user.username}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: user.fullName.isNotEmpty
                        ? Text(user.fullName, style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Campo de uma sessão no diálogo de configuração (apelido + session id).
class _CampoSessao {
  final TextEditingController label = TextEditingController();
  final TextEditingController sessionId = TextEditingController();
  void dispose() {
    label.dispose();
    sessionId.dispose();
  }
}

/// Diálogo para configurar o pool de sessões do Instagram (1 ou mais contas).
/// Mostra as sessões existentes (com status de erro) e permite remover ou adicionar novas.
class _ConfigSessoesDialog extends StatefulWidget {
  const _ConfigSessoesDialog();
  @override
  State<_ConfigSessoesDialog> createState() => _ConfigSessoesDialogState();
}

class _ConfigSessoesDialogState extends State<_ConfigSessoesDialog> {
  // Sessões já salvas no servidor (sem sessionId por segurança)
  List<Map<String, dynamic>> _sessoesExistentes = [];
  // Campos para adicionar novas
  final List<_CampoSessao> _novos = [_CampoSessao()];
  bool _salvando = false;
  bool _carregando = true;

  // Configurações de API
  final _rapidApiKeyCtrl = TextEditingController();
  final _rapidApiKey2Ctrl = TextEditingController();
  final _rapidApiKey3Ctrl = TextEditingController();
  final _pythonUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarStatus();
  }

  Future<void> _carregarStatus() async {
    final status = await InstagramService.fetchSessionsStatus();
    final apiConfig = await InstagramService.fetchApiConfig();
    if (mounted) {
      setState(() {
        _carregando = false;
        if (status != null) {
          _sessoesExistentes = List<Map<String, dynamic>>.from(
            status['sessions_list'] ?? [],
          );
        }
        if (apiConfig != null) {
          _rapidApiKeyCtrl.text = apiConfig['rapidapi_key'] ?? '';
          _rapidApiKey2Ctrl.text = apiConfig['rapidapi_key_2'] ?? '';
          _rapidApiKey3Ctrl.text = apiConfig['rapidapi_key_3'] ?? '';
          _pythonUrlCtrl.text = apiConfig['python_server_url'] ?? 'http://127.0.0.1:8500';
        }
      });
    }
  }

  Future<void> _salvarApiConfig() async {
    setState(() => _salvando = true);
    final ok = await InstagramService.saveApiConfig({
      'rapidapi_key': _rapidApiKeyCtrl.text.trim(),
      'rapidapi_key_2': _rapidApiKey2Ctrl.text.trim(),
      'rapidapi_key_3': _rapidApiKey3Ctrl.text.trim(),
      'python_server_url': _pythonUrlCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _salvando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'APIs salvas com sucesso' : 'Falha ao salvar. Backend rodando?'),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red,
    ));
  }

  void _adicionarCampo() => setState(() => _novos.add(_CampoSessao()));

  void _removerCampo(int i) {
    if (_novos.length == 1) return;
    setState(() => _novos.removeAt(i).dispose());
  }

  Future<void> _removerExistente(String label) async {
    setState(() => _salvando = true);
    final ok = await InstagramService.deleteSession(label);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (ok) {
      setState(() => _sessoesExistentes.removeWhere((s) => s['label'] == label));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sessão "$label" removida'), backgroundColor: Colors.green.shade700),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao remover. Servidor rodando?'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _salvar() async {
    final sessoes = <Map<String, String>>[];
    for (var i = 0; i < _novos.length; i++) {
      final sid = _novos[i].sessionId.text.trim();
      if (sid.isEmpty) continue;
      final apelido = _novos[i].label.text.trim();
      sessoes.add({'label': apelido.isEmpty ? 'sessao${_sessoesExistentes.length + i + 1}' : apelido, 'sessionid': sid});
    }
    if (sessoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe ao menos um Session ID'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _salvando = true);
    final total = await InstagramService.saveSessions(sessoes);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (total != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$total sessão(ões) salva(s) com sucesso'), backgroundColor: Colors.green.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao salvar. O servidor local (porta 8500) está rodando?'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _novos) {
      c.dispose();
    }
    _rapidApiKeyCtrl.dispose();
    _rapidApiKey2Ctrl.dispose();
    _rapidApiKey3Ctrl.dispose();
    _pythonUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings, color: Color(0xFF833AB4), size: 22),
          const SizedBox(width: 8),
          const Text('Configurações do Monitor'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: _carregando
            ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- APIs de coleta ---
                    const Text('APIs de coleta:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pythonUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL do servidor Python',
                        isDense: true,
                        border: OutlineInputBorder(),
                        helperText: 'Ex: http://127.0.0.1:8500',
                        prefixIcon: Icon(Icons.computer, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rapidApiKeyCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Chave RapidAPI 1',
                        isDense: true,
                        border: OutlineInputBorder(),
                        helperText: 'instagram-scraper-stable-api.p.rapidapi.com',
                        prefixIcon: Icon(Icons.vpn_key, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rapidApiKey2Ctrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Chave RapidAPI 2 (opcional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                        helperText: 'Usada como fallback quando a chave 1 for bloqueada',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rapidApiKey3Ctrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Chave RapidAPI 3 (opcional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                        helperText: 'Usada como fallback quando a chave 2 for bloqueada',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _salvando ? null : _salvarApiConfig,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Salvar APIs'),
                      ),
                    ),
                    const Divider(height: 20),
                    // Sessões existentes
                    if (_sessoesExistentes.isNotEmpty) ...[
                      const Text(
                        'Sessões configuradas:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      ..._sessoesExistentes.map((s) {
                        final label = s['label'] as String? ?? '';
                        final isActive = s['is_active'] as bool? ?? false;
                        final hasError = s['has_error'] as bool? ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: hasError
                                ? Colors.red.withValues(alpha: 0.05)
                                : isActive
                                    ? Colors.green.withValues(alpha: 0.05)
                                    : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasError
                                  ? Colors.red.withValues(alpha: 0.3)
                                  : isActive
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasError ? Icons.error : isActive ? Icons.check_circle : Icons.circle_outlined,
                                size: 16,
                                color: hasError ? Colors.red : isActive ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(
                                      hasError ? 'Erro — Instagram bloqueou esta sessão' : isActive ? 'Em uso' : 'Em espera no pool',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: hasError ? Colors.red : isActive ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasError)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Text('?', style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.w900)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: _salvando ? null : () => _removerExistente(label),
                                tooltip: 'Remover sessão',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                    ],
                    // Adicionar novas sessões
                    Text(
                      _sessoesExistentes.isEmpty
                          ? 'Nenhuma sessão configurada. Cole o Session ID abaixo (encontre em DevTools → Application → Cookies → instagram.com → sessionid).'
                          : 'Adicionar novas sessões (quanto mais contas, mais resiliente ao bloqueio):',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _novos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _novos[i].label,
                                    decoration: const InputDecoration(
                                      labelText: 'Apelido (opcional)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _novos[i].sessionId,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Session ID',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                      helperText: 'DevTools → Application → Cookies → instagram.com → sessionid',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: _novos.length == 1 ? null : () => _removerCampo(i),
                              tooltip: 'Remover',
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _adicionarCampo,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar outra conta'),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF833AB4), foregroundColor: Colors.white),
          child: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Salvar novas'),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Painel de Jobs e Interações
// ──────────────────────────────────────────────────────────────

class _PainelJobsDialog extends StatefulWidget {
  final String? username;
  const _PainelJobsDialog({this.username});

  @override
  State<_PainelJobsDialog> createState() => _PainelJobsDialogState();
}

class _PainelJobsDialogState extends State<_PainelJobsDialog> {
  static const _corRoxo = Color(0xFF833AB4);
  static const _corRosa = Color(0xFFE1306C);
  static const _corLaranja = Color(0xFFF77737);

  static const _nomeDisplayJob = {
    'InstagramDataCollector': 'Coleta Horária',
    'InstagramInteracaoFollowingJob': 'Interação Following',
  };

  static const _iconeJob = {
    'InstagramDataCollector': Icons.cloud_download_outlined,
    'InstagramInteracaoFollowingJob': Icons.people_alt_outlined,
  };

  bool _carregando = true;
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _interacoes;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final jobs = await InstagramService.fetchJobsStatus();
    final interacoes = (widget.username != null && widget.username!.isNotEmpty)
        ? await InstagramService.fetchInteracoes(widget.username!, limit: 30)
        : null;
    if (mounted) {
      setState(() {
        _carregando = false;
        _jobs = (jobs ?? [])
            .where((j) =>
                ['InstagramDataCollector', 'InstagramInteracaoFollowingJob'].contains(j['jobNome']))
            .toList();
        _interacoes = interacoes;
      });
    }
  }

  String _tempoRelativo(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'agora mesmo';
      if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'há ${diff.inHours}h';
      return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    } catch (_) {
      return '';
    }
  }

  String _formatarDataHora(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final alturaMaxima = MediaQuery.of(context).size.height * 0.80;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: alturaMaxima),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _carregando ? _buildSkeleton() : _buildCorpo(),
            ),
            _buildRodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_corRoxo, _corRosa, _corLaranja],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jobs e Interações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                if (widget.username != null && widget.username!.isNotEmpty)
                  Text(
                    '@${widget.username}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(3, (i) => _skeletonBloco(i)),
      ),
    );
  }

  Widget _skeletonBloco(int indice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: indice == 0 ? 120 : 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRotulo('Status dos Jobs', Icons.schedule_outlined, _corRoxo),
          const SizedBox(height: 10),
          if (_jobs.isEmpty)
            _buildEstadoVazioJobs()
          else
            ..._jobs.map(_buildJobCard),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 20),
          _buildRotulo('Interações detectadas', Icons.notifications_active_outlined, _corRosa),
          const SizedBox(height: 10),
          _buildSecaoInteracoes(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRotulo(String titulo, IconData icone, Color cor) {
    return Row(
      children: [
        Icon(icone, size: 15, color: cor),
        const SizedBox(width: 6),
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: cor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazioJobs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty_outlined, color: Colors.grey[400], size: 28),
          const SizedBox(width: 12),
          Text(
            'Nenhum job executado ainda.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final nome = job['jobNome'] as String? ?? '';
    final nomeDisplay = _nomeDisplayJob[nome] ?? nome;
    final icone = _iconeJob[nome] ?? Icons.settings_outlined;
    final status = job['status'] as String? ?? '';
    final inicio = job['iniciadoEm'] as String?;
    final durMs = job['duracaoMs'] as int?;
    final resultado = job['resultado'] as String? ?? '';

    final isOk = status == 'SUCESSO';
    final nunca = status.isEmpty;

    final corChip = nunca
        ? Colors.grey[400]!
        : isOk
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828);
    final corFundoChip = nunca
        ? Colors.grey[100]!
        : isOk
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE);
    final labelChip = nunca ? 'Nunca' : isOk ? 'Sucesso' : 'Erro';
    final iconeChip = nunca
        ? Icons.remove_circle_outline
        : isOk
            ? Icons.check_circle_outline
            : Icons.error_outline;

    final dataExibicao = _formatarDataHora(inicio);
    final tempoRel = _tempoRelativo(inicio);
    final durStr = durMs != null ? '${durMs}ms' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_corRoxo, _corRosa],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: Colors.white, size: 22),
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
                        nomeDisplay,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: corFundoChip,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconeChip, size: 11, color: corChip),
                          const SizedBox(width: 3),
                          Text(
                            labelChip,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: corChip,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (dataExibicao.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      children: [
                        TextSpan(text: dataExibicao),
                        if (tempoRel.isNotEmpty)
                          TextSpan(
                            text: '  ·  $tempoRel',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (durStr != null)
                          TextSpan(
                            text: '  ·  $durStr',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Aguardando primeira execução',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                  ),
                if (resultado.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    resultado,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoInteracoes() {
    if (widget.username == null || widget.username!.isEmpty) {
      return _buildEstadoVazioInteracoes('Selecione um perfil para ver interações.');
    }

    if (_interacoes == null) {
      return _buildEstadoVazioInteracoes('Erro ao carregar interações.');
    }

    final curtidas = List<Map<String, dynamic>>.from(_interacoes!['curtidas'] ?? []);
    final comentarios = List<Map<String, dynamic>>.from(_interacoes!['comentarios'] ?? []);
    final totalCurtidas = _interacoes!['totalCurtidas'] ?? curtidas.length;
    final totalComentarios = _interacoes!['totalComentarios'] ?? comentarios.length;

    if (curtidas.isEmpty && comentarios.isEmpty) {
      return _buildEstadoVazioInteracoes(
        'Nenhuma interação detectada para @${widget.username}.\nO job roda todos os dias às 23:59.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (curtidas.isNotEmpty) ...[
          _buildSubtituloInteracao(
            Icons.favorite_rounded,
            '$totalCurtidas curtida${totalCurtidas != 1 ? 's' : ''}',
            _corRosa,
          ),
          const SizedBox(height: 8),
          ...curtidas.take(10).map((c) => _buildCartaoInteracao(c, false)),
          if (comentarios.isNotEmpty) const SizedBox(height: 14),
        ],
        if (comentarios.isNotEmpty) ...[
          _buildSubtituloInteracao(
            Icons.chat_bubble_rounded,
            '$totalComentarios comentário${totalComentarios != 1 ? 's' : ''}',
            _corRoxo,
          ),
          const SizedBox(height: 8),
          ...comentarios.take(10).map((c) => _buildCartaoInteracao(c, true)),
        ],
      ],
    );
  }

  Widget _buildEstadoVazioInteracoes(String mensagem) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.notifications_none_outlined, size: 36, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              mensagem,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtituloInteracao(IconData icone, String label, Color cor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 14, color: cor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cor,
          ),
        ),
      ],
    );
  }

  Widget _buildCartaoInteracao(Map<String, dynamic> item, bool isComentario) {
    final owner = item['postOwnerUsername'] as String? ?? '';
    final shortcode = item['postShortcode'] as String? ?? '';
    final texto = item['textoComentario'] as String? ?? '';
    final detected = item['detectedAt'] as String? ?? '';
    final interactor = widget.username ?? '';

    final tempoRel = _tempoRelativo(detected.isNotEmpty ? detected : null);
    final corBase = isComentario ? _corRoxo : _corRosa;
    final inicial = interactor.isNotEmpty ? interactor[0].toUpperCase() : '?';

    final descricao = isComentario
        ? '@$interactor comentou em um post de @$owner'
        : '@$interactor curtiu um post de @$owner';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corBase.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: corBase.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [corBase, corBase.withValues(alpha: 0.60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (tempoRel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        tempoRel,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                if (shortcode.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.link, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(
                        'instagram.com/p/$shortcode',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
                if (isComentario && texto.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: _corRoxo.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _corRoxo.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      '"$texto"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4A4A6A),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Atualizar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _corRoxo,
              side: const BorderSide(color: _corRoxo),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _corRoxo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Fechar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
