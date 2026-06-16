import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final String displayUrl;
  final String? caption;
  final int likes;
  final int comments;
  final String timestamp;
  final bool isVideo;
  final String? videoUrl;

  InstagramPost({
    required this.id,
    required this.displayUrl,
    this.caption,
    required this.likes,
    required this.comments,
    required this.timestamp,
    required this.isVideo,
    this.videoUrl,
  });

  factory InstagramPost.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('display_url')) {
      return InstagramPost(
        id: json['id'] ?? '',
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
      id: json['id'] ?? '',
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

  static String get _backendUrl {
    const env = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://127.0.0.1:9001');
    return env;
  }

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

  static Future<InstagramProfile?> fetchProfile(String username) async {
    final clean = username.replaceAll('@', '').trim();
    
    if (_localAvailable) {
      try {
        final r = await http.get(Uri.parse('$_localApi/profile?username=$clean')).timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          final data = json.decode(r.body);
          if (!data.containsKey('error')) {
            final postsData = await fetchPosts(clean);
            return InstagramProfile.fromJson(data).copyWith(posts: postsData);
          }
        }
      } catch (_) {}
    }

    try {
      final url = Uri.parse('https://i.instagram.com/api/v1/users/web_profile_info/?username=$clean');
      final response = await http.get(url, headers: _mobileHeaders).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return InstagramProfile.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  static Future<List<InstagramPost>> fetchPosts(String username, {int amount = 12}) async {
    if (_localAvailable) {
      try {
        final r = await http.get(Uri.parse('$_localApi/posts?username=$username&amount=$amount')).timeout(const Duration(seconds: 20));
        if (r.statusCode == 200) {
          final data = json.decode(r.body);
          if (data.containsKey('posts')) {
            return (data['posts'] as List).map((p) => InstagramPost.fromJson(p)).toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<InstagramLiker>> fetchLikers(String mediaId) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_localApi/likers?media_id=$mediaId')).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('likers')) {
          return (data['likers'] as List).map((l) => InstagramLiker.fromJson(l)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowers(String username, {int amount = 50}) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_localApi/followers?username=$username&amount=$amount')).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('followers')) {
          return (data['followers'] as List).map((f) => InstagramLiker.fromJson(f)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<InstagramLiker>> fetchFollowing(String username, {int amount = 50}) async {
    if (!_localAvailable) return [];
    try {
      final r = await http.get(Uri.parse('$_localApi/following?username=$username&amount=$amount')).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('following')) {
          return (data['following'] as List).map((f) => InstagramLiker.fromJson(f)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  static Future<bool> untrackProfile(int id) async {
    try {
      final r = await http.delete(
        Uri.parse('$_backendUrl/api/instagram/tracked/$id'),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> trackProfile(String username) async {
    try {
      final r = await http.post(
        Uri.parse('$_backendUrl/api/instagram/track'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username}),
      ).timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> takeSnapshot(String username) async {
    if (!_localAvailable) return null;

    final followers = await fetchFollowers(username, amount: 100);
    final following = await fetchFollowing(username, amount: 100);

    final followerData = followers.map((f) => {'username': f.username, 'full_name': f.fullName}).toList();
    final followingData = following.map((f) => {'username': f.username, 'full_name': f.fullName}).toList();

    final posts = await fetchPosts(username, amount: 12);
    final postLikes = <String, List<Map<String, String>>>{};
    for (final post in posts) {
      final likers = await fetchLikers(post.id);
      postLikes[post.id] = likers.map((l) => {'username': l.username, 'full_name': l.fullName}).toList();
    }

    try {
      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'snapshotType': 'followers',
          'data': json.encode(followerData),
        }),
      ).timeout(const Duration(seconds: 30));

      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'snapshotType': 'following',
          'data': json.encode(followingData),
        }),
      ).timeout(const Duration(seconds: 30));

      await http.post(
        Uri.parse('$_backendUrl/api/instagram/snapshot'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'snapshotType': 'post_likes',
          'data': json.encode(postLikes),
        }),
      ).timeout(const Duration(seconds: 30));

      return {
        'followers': followerData.length,
        'following': followingData.length,
        'posts_liked': postLikes.length,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<TimelineEvent>> fetchTimeline(String username, {int days = 30}) async {
    try {
      final r = await http.get(Uri.parse('$_backendUrl/api/instagram/timeline/$username'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('events')) {
          return (data['events'] as List).map((e) => TimelineEvent.fromJson(e)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTrackedProfiles() async {
    try {
      final r = await http.get(Uri.parse('$_backendUrl/api/instagram/tracked'))
          .timeout(const Duration(seconds: 10));
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
      final r = await http.get(Uri.parse('$_backendUrl/api/instagram/change-logs/$username'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = json.decode(r.body);
        if (data.containsKey('logs')) {
          return List<Map<String, dynamic>>.from(data['logs']);
        }
      }
    } catch (_) {}
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
