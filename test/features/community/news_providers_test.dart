import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/community/models/news_article.dart';

void main() {
  group('NewsArticle', () {
    test('fromApi parses public payload', () {
      final article = NewsArticle.fromApi({
        'id': 'n1',
        'title': 'Runway recap',
        'summary': 'Highlights',
        'body': 'Full story',
        'coverImageUrl': 'https://cdn.example.com/a.jpg',
        'isFeatured': true,
        'publishedAt': '2026-06-01T12:00:00.000Z',
        'authorId': 'admin-1',
        'authorName': 'Editor',
      });

      expect(article.id, 'n1');
      expect(article.title, 'Runway recap');
      expect(article.isFeatured, isTrue);
      expect(article.coverImageUrl, 'https://cdn.example.com/a.jpg');
      expect(article.publishedAt, isNotNull);
    });
  });

  group('FashionNewsPage', () {
    test('fromApi splits featured and articles', () {
      final page = FashionNewsPage.fromApi({
        'featured': {
          'id': 'f1',
          'title': 'Hero',
          'summary': 'Teaser',
          'body': 'Body',
        },
        'articles': [
          {
            'id': 'a1',
            'title': 'Recent',
            'summary': 'S',
            'body': 'B',
          },
        ],
        'nextCursor': '2026-05-01T00:00:00.000Z',
      });

      expect(page.featured?.id, 'f1');
      expect(page.articles, hasLength(1));
      expect(page.nextCursor, isNotNull);
    });
  });
}
