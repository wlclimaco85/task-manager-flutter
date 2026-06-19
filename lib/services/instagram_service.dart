import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/api_links.dart';

class InstagramException implements Exception {
  final String mensagem;
  const InstagramException(this.mensagem);
  @override
  String toString() => mensagem;
}

class InstagramProfile {
  final String username;
  final String fullName;
  final String biography;
  final String profilePicUrl;
  final int followers;
  final int following;
  final int posts;
  final bool isPrivate;
  final bool isVerified;
  final String? externalUrl;
  final List<InstagramPost> recentPosts;

  InstagramProfile({
    required this.username,
    required this.fullName,
    required this.biography,
    required this.profilePicUrl,
    required this.followers,
    required this.following,
    required this.posts,
    required this.isPrivate,
    required this.isVerified,
    this.externalUrl,
    this.recentPosts = const [],
  });

  factory InstagramProfile.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('followers')) {
      return InstagramProfile(
        username: json['username'] ?? '',
        fullName: json['full_name'] ?? '',
        biography: json['biography'] ?? '',
        profilePicUrl: json['profile_pic_url'] ?? json['hd_profile_pic'] ?? '',
        followers: json['followers'] ?? 0,
        following: json['following'] ?? 0,
        posts: json['posts'] ?? 0,
        isPrivate: json['is_private'] ?? false,
        isVerified: json['is_verified'] ?? false,
        externalUrl: json['external_url'],
      );
    }
    final user = json['data']?['user'] ?? json;
    final edgeFollowedBy = user['edge_followed_by'] ?? {};
    final edgeFollow = user['edge_follow'] ?? {};
    final edgeMedia = user['edge_owner_to_timeline_media'] ?? {};
    return InstagramProfile(
      username: user['username'] ?? '',
      fullName: user['full_name'] ?? '',
      biography: user['biography'] ?? '',
      profilePicUrl: user['profile_pic_url_hd'] ?? user['profile_pic_url'] ?? '',
      followers: edgeFollowedBy['count'] ?? 0,
      following: edgeFollow['count'] ?? 0,
      posts: edgeMedia['count'] ?? 0,
      isPrivate: user['is_private'] ?? false,
      isVerified: user['is_verified'] ?? false,
      externalUrl: user['external_url'],
    );
  }
}

class InstagramPost {
  final String id;
  final String shortcode;
  final String displayUrl;
  final String? caption;
  final int likes;
  final int comments;
  final String timestamp;
  final bool isVideo;
  final String? videoUrl;

  InstagramPost({
    required this.id,
    required this.shortcode,
    required this.displayUrl,
    this.caption,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.isVideo,
    this.videoUrl,
  });

  /// URL estavel para a imagem do post.
  /// Usa shortcode (nao expira) quando disponivel; fallback para display_url.
  String get imageUrl {
    if (shortcode.isNotEmpty) {
      return 'https://www.instagram.com/p/$shortcode/media/?size=t';
    }
    return displayUrl;
  }

  factory InstagramPost.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('display_url')) {
      return InstagramPost(
        id: (json['id'] ?? '').toString(),
        shortcode: json['shortcode'] ?? json['id']?.toString() ?? '',
        displayUrl: json['display_url'] ?? '',
        caption: json['caption'],
        likes: json['likes'] ?? 0,
        comments: json['comments'] ?? 0,
        timestamp: json['timestamp'] ?? '',
        isVideo: json['is_video'] ?? false,
        videoUrl: json['video_url'],
      );
    }
    final edgeLiked = json['edge_liked_by'] ?? json['edge_media_preview_like'] ?? {};
    final edgeComment = json['edge_media_to_comment'] ?? {};
    return InstagramPost(
      id: (json['id'] ?? '').toString(),
      shortcode: json['shortcode'] ?? json['id']?.toString() ?? '',
      displayUrl: json['display_url'] ?? '',
      caption: json['edge_media_to_caption']?['edges']?.isNotEmpty == true
          ? json['edge_media_to_caption']['edges'][0]['node']['text']
          : json['accessibility_caption'] ?? '',
      likes: edgeLiked['count'] ?? 0,
      comments: edgeComment['count'] ?? 0,
      timestamp: json['taken_at_timestamp']?.toString() ?? '',
      isVideo: json['is_video'] ?? false,
      videoUrl: null,
    );
  }

  String get timeAgo {
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      return '${diff.inMinutes}min';
    } catch (_) {
      return '';
    }
  }
}

class InstagramLiker {
  final String username;
  final String fullName;
  InstagramLiker({required this.username, required this.fullName});
  
  factory InstagramLiker.fromJson(Map<String, dynamic> json) {
    return InstagramLiker(
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }
}

class TimelineEvent {
  final String type;
  final String username;
  final String fullName;
  final String date;
  final String? postId;
  final String? text;
  final int? likes;

  TimelineEvent({
    required this.type,
    required this.username,
    required this.fullName,
    required this.date,
    this.postId,
    this.text,
    this.likes,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      type: json['type'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      date: json['date'] ?? '',
      postId: json['post_id'],
      text: json['text'],
      likes: json['likes'],
    );
  }

  String get typeLabel {
    switch (type) {
      case 'new_follower': return 'Comecou a seguir voce';
      case 'unfollowed': return 'Deixou de seguir voce';
      case 'you_followed': return 'Voce comecou a seguir';
      case 'unfollowed_by_you': return 'Voce deixou de seguir';
      case 'liked_post': return 'Curtiu sua foto';
      case 'unliked_post': return 'Deixou de curtir sua foto';
      case 'comment': return 'Comentou';
      default: return type;
    }
  }

  String get emoji {
    switch (type) {
      case 'new_follower': return '\u{1F465}';
      case 'unfollowed': return '\u{1F6AB}';
      case 'you_followed': return '\u{1F464}';
      case 'unfollowed_by_you': return '\u{1F519}';
      case 'liked_post': return '\u{2764}\u{FE0F}';
      case 'unliked_post': return '\u{1F941}';
      case 'comment': return '\u{1F4AC}';
      default: return '\u{1F514}';
    }
  }

  DateTime? get dateTime {
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  String get timeAgo {
    final dt = dateTime;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min';
    return 'agora';
  }

  String get dateFormatted {
    final dt = dateTime;
    if (dt == null) return date;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(eventDay).inDays;
    String dayLabel;
    if (diff == 0) dayLabel = 'Hoje';
    else if (diff == 1) dayLabel = 'Ontem';
    else if (diff < 7) dayLabel = 'Ha $diff dias';
    else dayLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    return '$dayLabel \u{2022} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class InstagramService {
  static const _localApi = 'http://127.0.0.1:8500';
  static bool _localAvailable = false;

  // Base do backend Java (AppAcademia). Usa a mesma base canônica do app
  // (ApiLinks.baseUrl = $BACKEND_URL/boletobancos) — o context-path /boletobancos
  // é obrigatório, sem ele todos os endpoints Java retornam 404.
  static String get _backendUrl => ApiLinks.baseUrl;

  static const _mobileHeaders = {
    'User-Agent': 'Instagram 301.0.0.27.109 Android (30/11; 420dpi; 1080x2400; samsung; SM-A525F; a52; exynos1280; en_US; 516783258)',
    'X-IG-App-ID': '936619743392459',
    'X-IG-Client-ID': 'IGSB',
    'Accept-Language': 'en-US',
  };

  static Future<void> checkLocalApi() async {
    try {
      final r = await http.get(Uri.parse('$_localApi/health')).timeout(const Duration(seconds: 2));
      _localAvailable = r.statusCode == 200;
    } catch (_) {
      _localAvailable = false;
    }
  }

  static bool get hasLocalApi => _localAvailable;

  /// Retorna perfil do banco de dados local via backend Java.
  /// Lança [InstagramException] se o perfil não estiver monitorado.
  static Future<InstagramProfile?> fetchProfile(String username) async {
    final clean = username.replaceAll('@', '').trim();
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/perfis/$clean'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return InstagramProfile.fromJson(json.decode(r.body));
      }
      if (r.statusCode == 404) {
        throw InstagramException('Perfil não monitorado. Adicione ao monitoramento primeiro.');
      }
    } on InstagramException {
      rethrow;
    } catch (_) {}
    return null;
  }

  static final InstagramException notFound = InstagramException('Perfil nao encontrado ou privado');

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  static Future<bool> untrackProfile(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/tracked/$id'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> trackProfile(String username, {String fullName = '', String profilePicUrl = ''}) async {
    try {
      final r = await http.post(
        Uri.parse('$_backendUrl/api/instagram/track'),
        headers: await AuthService().jsonHeaders(),
        body: json.encode({
          'username': username,
          'fullName': fullName,
          'profilePicUrl': profilePicUrl,
        }),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchTimelinePaginado(
      String username, {int page = 0, int size = 100}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/timeline/$username?page=$page&size=$size'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        final eventos = (data['events'] as List? ?? [])
            .map((e) => TimelineEvent.fromJson(e))
            .toList();
        return {
          'events': eventos,
          'total': data['total'] ?? 0,
          'hasMore': data['hasMore'] ?? false,
          'page': data['page'] ?? page,
        };
      }
    } catch (_) {}
    return {'events': <TimelineEvent>[], 'total': 0, 'hasMore': false, 'page': page};
  }

  /// Lista os usuarios de uma relacao do dashboard.
  /// tipo: 'mutuos' | 'sigo_nao_me_segue' | 'me_segue_nao_sigo'.
  static Future<List<InstagramLiker>> fetchRelacaoDashboard(String username, String tipo) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/dashboard/$username/relacao?tipo=$tipo'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return (data['itens'] as List? ?? [])
            .map((e) => InstagramLiker(username: e['username'] ?? '', fullName: e['fullName'] ?? ''))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Resumo do dashboard: relacoes atuais + serie temporal de seguidores/seguindo.
  static Future<Map<String, dynamic>> fetchDashboard(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/dashboard/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  static Future<List<TimelineEvent>> fetchTimeline(String username, {int days = 30}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/timeline/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('events')) {
          return (data['events'] as List).map((e) => TimelineEvent.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> limparChangeLogs(String username) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/change-logs/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> limparTimeline(String username) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/timeline/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTrackedProfiles() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/tracked'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('profiles')) {
          return List<Map<String, dynamic>>.from(data['profiles']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchChangeLogs(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/change-logs/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowersFromDb(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/followers/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('followers')) {
          return (data['followers'] as List)
              .map((f) => InstagramLiker(username: f['username'] ?? '', fullName: f['fullName'] ?? ''))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowingFromDb(String username) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/following/$username'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('following')) {
          return (data['following'] as List)
              .map((f) => InstagramLiker(username: f['username'] ?? '', fullName: f['fullName'] ?? ''))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Retorna lista com última execução de cada job do monitor.
  static Future<List<Map<String, dynamic>>?> fetchJobsStatus() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/admin/jobs'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return null;
  }

  /// Retorna curtidas e comentários detectados para o username monitorado.
  static Future<Map<String, dynamic>?> fetchInteracoes(String username, {int limit = 20}) async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/interacoes?username=${Uri.encodeComponent(username)}&limit=$limit'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Carrega configurações de API (rapidapi_key, python_server_url) do backend Java.
  static Future<Map<String, String>?> fetchApiConfig() async {
    try {
      final r = await http.get(
        Uri.parse('$_backendUrl/api/instagram/config'),
        headers: await AuthService().jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        return data.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
    } catch (_) {}
    return null;
  }

  /// Salva configurações de API no backend Java.
  static Future<bool> saveApiConfig(Map<String, String> config) async {
    try {
      final headers = await AuthService().jsonHeaders();
      final r = await http.put(
        Uri.parse('$_backendUrl/api/instagram/config'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode(config),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// Status do pool de sessões no servidor Python local (total, ativa, labels).
  static Future<Map<String, dynamic>?> fetchSessionsStatus() async {
    try {
      final r = await http.get(Uri.parse('$_localApi/sessions'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return json.decode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// Remove uma sessão do pool pelo apelido. Retorna true se removida.
  static Future<bool> deleteSession(String label) async {
    try {
      final r = await http.delete(
        Uri.parse('$_localApi/sessions/${Uri.encodeComponent(label)}'),
      ).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Importa manualmente uma lista de usernames para followers ou following do perfil monitorado.
  /// tipo: 'followers' | 'following'. Retorna {inseridos, duplicatasIgnoradas} ou null em falha.
  static Future<Map<String, dynamic>?> importarManual(
      String username, String tipo, List<String> usernames) async {
    try {
      final headers = await AuthService().jsonHeaders();
      final r = await http.post(
        Uri.parse('$_backendUrl/api/instagram/perfis/$username/importar-manual'),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: json.encode({'tipo': tipo, 'usernames': usernames}),
      ).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        return json.decode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Salva o pool de sessões (1+ contas) no servidor Python local.
  /// Cada item: {'label': ..., 'sessionid': ...}. Retorna o total salvo, ou null em falha.
  static Future<int?> saveSessions(List<Map<String, String>> sessoes) async {
    try {
      final r = await http.post(
        Uri.parse('$_localApi/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sessions': sessoes}),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        return data['total'] as int?;
      }
    } catch (_) {}
    return null;
  }

  /// Busca posts do username a partir do banco de dados via backend Java.
  static Future<List<InstagramPost>> fetchPostsFromDb(String username) async {
    final backendUrl = ApiLinks.baseUrl;
    final r = await http.get(
      Uri.parse('$backendUrl/api/instagram/posts/$username'),
      headers: await AuthService().jsonHeaders(),
    ).timeout(const Duration(seconds: 20));
    if (r.statusCode == 200) {
      final body = json.decode(r.body);
      final List<dynamic> lista =
          body is List ? body : (body['content'] ?? body['data'] ?? []);
      return lista
          .map((e) => InstagramPost.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

extension _ProfileCopy on InstagramProfile {
  InstagramProfile copyWith({List<InstagramPost>? posts}) {
    return InstagramProfile(
      username: username,
      fullName: fullName,
      biography: biography,
      profilePicUrl: profilePicUrl,
      followers: followers,
      following: following,
      posts: posts?.length ?? this.posts,
      isPrivate: isPrivate,
      isVerified: isVerified,
      externalUrl: externalUrl,
      recentPosts: posts ?? this.recentPosts,
    );
  }
}
