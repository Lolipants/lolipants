/// Community feed post snapshot.
class Post {
  /// Creates a post model.
  const Post({
    required this.id,
    required this.body,
    required this.postedAt,
    this.authorName = 'Designer',
    this.imageUrls = const [],
    this.tags = const [],
    this.reactionCount = 0,
    this.commentCount = 0,
  });

  /// Parses API payload.
  factory Post.fromApi(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      postedAt: DateTime.tryParse(json['posted_at']?.toString() ?? '') ??
          DateTime.now(),
      authorName: json['author_name']?.toString() ??
          json['authorName']?.toString() ??
          'Designer',
      imageUrls:
          _asStringList(json['image_urls']) ??
          _asStringList(json['imageUrls']) ??
          const [],
      tags: _asStringList(json['tags']) ?? const [],
      reactionCount: int.tryParse(json['reaction_count']?.toString() ?? '') ??
          (json['reactionCount'] as int? ?? 0),
      commentCount: int.tryParse(json['comment_count']?.toString() ?? '') ??
          (json['commentCount'] as int? ?? 0),
    );
  }

  /// Identifier.
  final String id;

  /// Main text content.
  final String body;

  /// Display author name.
  final String authorName;

  /// Attached image URLs.
  final List<String> imageUrls;

  /// Post tags.
  final List<String> tags;

  /// Reaction counter.
  final int reactionCount;

  /// Comment counter.
  final int commentCount;

  /// Creation timestamp.
  final DateTime postedAt;
}

List<String>? _asStringList(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return null;
}
