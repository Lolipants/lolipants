import 'dart:convert';

/// Reaction type enum mirroring the backend's allowed reaction_type strings.
enum ReactionType { love, fire, clap, wow }

/// Converts a reaction string (e.g. 'love') into its enum.
ReactionType? reactionTypeFromString(String? raw) {
  if (raw == null) return null;
  switch (raw.toLowerCase()) {
    case 'love':
      return ReactionType.love;
    case 'fire':
      return ReactionType.fire;
    case 'clap':
      return ReactionType.clap;
    case 'wow':
      return ReactionType.wow;
  }
  return null;
}

/// Serialises a reaction enum back to its backend string.
String reactionTypeToString(ReactionType type) {
  switch (type) {
    case ReactionType.love:
      return 'love';
    case ReactionType.fire:
      return 'fire';
    case ReactionType.clap:
      return 'clap';
    case ReactionType.wow:
      return 'wow';
  }
}

/// Community feed post snapshot.
class Post {
  /// Creates a post model.
  const Post({
    required this.id,
    required this.authorId,
    required this.body,
    required this.postedAt,
    this.authorName = 'Designer',
    this.authorAvatarUrl,
    this.isVerifiedDesigner = false,
    this.imageUrls = const [],
    this.tags = const [],
    this.reactionCount = 0,
    this.commentCount = 0,
    this.currentUserReaction,
  });

  /// Parses API payload from GET /posts or GET /posts/:id.
  factory Post.fromApi(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString() ??
          json['author_id']?.toString() ??
          '',
      body: json['body']?.toString() ?? '',
      postedAt: DateTime.tryParse(
            json['postedAt']?.toString() ??
                json['posted_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      authorName: json['authorName']?.toString() ??
          json['author_name']?.toString() ??
          'Designer',
      authorAvatarUrl: json['authorAvatarUrl']?.toString() ??
          json['author_avatar_url']?.toString(),
      isVerifiedDesigner: json['isVerifiedDesigner'] == true ||
          json['author_is_pro_designer'] == true ||
          _asInt(json['author_is_pro_designer']) == 1 ||
          _asInt(json['is_verified_designer']) == 1,
      imageUrls: _asStringList(json['imageUrls']) ??
          _asStringList(json['image_urls']) ??
          _asStringList(json['images']) ??
          const [],
      tags: _asStringList(json['tags']) ?? const [],
      reactionCount: _asInt(json['reactionCount']) ??
          _asInt(json['reaction_count']) ??
          0,
      commentCount: _asInt(json['commentCount']) ??
          _asInt(json['comment_count']) ??
          0,
      currentUserReaction: reactionTypeFromString(
        json['currentUserReaction']?.toString() ??
            json['my_reaction']?.toString(),
      ),
    );
  }

  /// Identifier.
  final String id;

  /// Author user id.
  final String authorId;

  /// Main text content.
  final String body;

  /// Display author name.
  final String authorName;

  /// Optional author avatar URL.
  final String? authorAvatarUrl;

  /// True when the author has the `is_pro_designer` flag set.
  final bool isVerifiedDesigner;

  /// Attached image URLs.
  final List<String> imageUrls;

  /// Post tags.
  final List<String> tags;

  /// Reaction counter.
  final int reactionCount;

  /// Comment counter.
  final int commentCount;

  /// Current viewer's active reaction, or null if none.
  final ReactionType? currentUserReaction;

  /// Creation timestamp.
  final DateTime postedAt;

  /// Post duplicate with optional overrides (used for optimistic updates).
  Post copyWith({
    int? reactionCount,
    int? commentCount,
    ReactionType? currentUserReaction,
    bool clearReaction = false,
  }) {
    return Post(
      id: id,
      authorId: authorId,
      body: body,
      postedAt: postedAt,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      isVerifiedDesigner: isVerifiedDesigner,
      imageUrls: imageUrls,
      tags: tags,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      currentUserReaction:
          clearReaction ? null : currentUserReaction ?? this.currentUserReaction,
    );
  }
}

List<String>? _asStringList(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  if (value is String && value.isNotEmpty) {
    try {
      final parsed = jsonDecode(value);
      if (parsed is List) {
        return parsed.map((e) => e.toString()).toList(growable: false);
      }
    } catch (_) {}
  }
  return null;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  if (value is String) return int.tryParse(value);
  return null;
}
