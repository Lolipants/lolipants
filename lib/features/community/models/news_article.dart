/// Admin-curated fashion news article.
class NewsArticle {
  /// Creates a news article.
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    this.coverImageUrl,
    this.isFeatured = false,
    this.publishedAt,
    this.authorId,
    this.authorName,
  });

  /// Parses public API payload from GET /news.
  factory NewsArticle.fromApi(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl']?.toString() ??
          json['cover_image_url']?.toString(),
      isFeatured:
          json['isFeatured'] == true || json['is_featured'] == 1,
      publishedAt: DateTime.tryParse(
        json['publishedAt']?.toString() ??
            json['published_at']?.toString() ??
            '',
      ),
      authorId: json['authorId']?.toString() ?? json['author_id']?.toString(),
      authorName:
          json['authorName']?.toString() ?? json['author_name']?.toString(),
    );
  }

  /// Article id.
  final String id;

  /// Localized headline.
  final String title;

  /// Localized teaser for cards and hero.
  final String summary;

  /// Localized full article body.
  final String body;

  /// Hero/cover image URL.
  final String? coverImageUrl;

  /// Whether this article is the featured hero item.
  final bool isFeatured;

  /// Publication timestamp.
  final DateTime? publishedAt;

  /// Author user id.
  final String? authorId;

  /// Author display name.
  final String? authorName;
}

/// Paginated fashion news list from GET /news.
class FashionNewsPage {
  /// Creates a page of news articles.
  const FashionNewsPage({
    this.featured,
    this.articles = const [],
    this.nextCursor,
  });

  /// Parses GET /news response.
  factory FashionNewsPage.fromApi(Map<String, dynamic> json) {
    final featuredRaw = json['featured'];
    return FashionNewsPage(
      featured: featuredRaw is Map<String, dynamic>
          ? NewsArticle.fromApi(featuredRaw)
          : null,
      articles: (json['articles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(NewsArticle.fromApi)
          .toList(growable: false),
      nextCursor: json['nextCursor']?.toString(),
    );
  }

  /// Featured hero article, if any.
  final NewsArticle? featured;

  /// Recent articles excluding featured.
  final List<NewsArticle> articles;

  /// Cursor for the next page.
  final String? nextCursor;
}
