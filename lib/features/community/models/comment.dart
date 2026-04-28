/// Comment on a community post.
class PostComment {
  /// Creates a comment.
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorAvatarUrl,
    this.isVerifiedDesigner = false,
  });

  /// Parses API payload.
  factory PostComment.fromApi(Map<String, dynamic> json) {
    return PostComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? json['post_id']?.toString() ?? '',
      authorId:
          json['authorId']?.toString() ?? json['author_id']?.toString() ?? '',
      authorName: json['authorName']?.toString() ??
          json['author_name']?.toString() ??
          'Lolipants User',
      authorAvatarUrl: json['authorAvatarUrl']?.toString() ??
          json['author_avatar_url']?.toString(),
      isVerifiedDesigner: json['isVerifiedDesigner'] == true ||
          json['author_is_pro_designer'] == true,
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ??
                json['created_at']?.toString() ??
                '',
          ) ??
          DateTime.now(),
    );
  }

  /// Unique identifier.
  final String id;

  /// Parent post id.
  final String postId;

  /// Author user id.
  final String authorId;

  /// Display name.
  final String authorName;

  /// Optional avatar url.
  final String? authorAvatarUrl;

  /// Verified/pro designer flag.
  final bool isVerifiedDesigner;

  /// Comment text.
  final String body;

  /// Comment creation timestamp.
  final DateTime createdAt;
}
