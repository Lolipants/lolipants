import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/community/models/commission.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';

void main() {
  group('Post.fromApi', () {
    test('parses camelCase payload returned by /posts endpoints', () {
      final post = Post.fromApi({
        'id': 'p1',
        'authorId': 'a1',
        'authorName': 'Nora',
        'isVerifiedDesigner': true,
        'body': 'hello',
        'imageUrls': ['https://a/1.png', 'https://a/2.png'],
        'tags': ['thobe', 'showcase'],
        'reactionCount': 2,
        'commentCount': 3,
        'currentUserReaction': 'love',
        'postedAt': '2026-04-15T10:00:00Z',
      });
      expect(post.id, 'p1');
      expect(post.authorName, 'Nora');
      expect(post.isVerifiedDesigner, isTrue);
      expect(post.imageUrls.length, 2);
      expect(post.tags, ['thobe', 'showcase']);
      expect(post.reactionCount, 2);
      expect(post.commentCount, 3);
      expect(post.currentUserReaction, ReactionType.love);
    });

    test('falls back to snake_case and JSON-string columns from D1', () {
      final post = Post.fromApi({
        'id': 'p2',
        'author_id': 'a2',
        'author_name': 'Omar',
        'author_is_pro_designer': 1,
        'body': 'snake',
        'image_urls': '["https://a/1.png"]',
        'tags': '["abaya"]',
        'reaction_count': '4',
        'comment_count': '5',
        'my_reaction': 'fire',
        'posted_at': '2026-04-15T10:00:00Z',
      });
      expect(post.authorId, 'a2');
      expect(post.isVerifiedDesigner, isTrue);
      expect(post.imageUrls, ['https://a/1.png']);
      expect(post.tags, ['abaya']);
      expect(post.reactionCount, 4);
      expect(post.commentCount, 5);
      expect(post.currentUserReaction, ReactionType.fire);
    });
  });

  group('Post.copyWith', () {
    test('clearReaction sets currentUserReaction to null', () {
      final p = Post(
        id: 'p',
        authorId: 'a',
        body: 'b',
        postedAt: DateTime(2026),
        currentUserReaction: ReactionType.love,
        reactionCount: 3,
      );
      final cleared = p.copyWith(reactionCount: 2, clearReaction: true);
      expect(cleared.currentUserReaction, isNull);
      expect(cleared.reactionCount, 2);
    });
  });

  group('Commission / DesignerEarnings', () {
    test('parses commission payload joined with order/design info', () {
      final c = Commission.fromApi({
        'id': 'c1',
        'order_id': 'o1',
        'designer_id': 'd1',
        'buyer_id': 'b1',
        'amount': 49,
        'percentage': 10,
        'currency': 'QAR',
        'status': 'approved',
        'design_name': 'Thobe',
        'order_status': 'delivered',
        'total_price': 490,
        'delivery_city': 'Doha',
        'created_at': '2026-04-15T10:00:00Z',
      });
      expect(c.status, CommissionStatus.approved);
      expect(c.amount, 49);
      expect(c.designName, 'Thobe');
      expect(c.orderTotal, 490);
    });

    test('maps byStatus bucket totals and computes lifetime', () {
      final e = DesignerEarnings.fromApi({
        'currency': 'QAR',
        'byStatus': {
          'pending': {'count': 1, 'total': 49},
          'approved': {'count': 1, 'total': 49},
          'paid': {'count': 2, 'total': 80},
          'void': {'count': 1, 'total': 49},
        },
      });
      expect(e.pending.total, 49);
      expect(e.approved.total, 49);
      expect(e.paid.total, 80);
      expect(e.voided.total, 49);
      // lifetime excludes voided.
      expect(e.lifetimeTotal, 49 + 49 + 80);
    });
  });

  group('ShowcaseItem.fromApi', () {
    test('parses nested designer mini payload', () {
      final item = ShowcaseItem.fromApi({
        'designId': 'd1',
        'name': 'Midnight Thobe',
        'garmentType': 'thobe',
        'primaryColour': '#0A1A2F',
        'orderCount': 3,
        'createdAt': '2026-04-15T10:00:00Z',
        'designer': {
          'id': 'designer-1',
          'name': 'Nora',
          'isProDesigner': true,
        },
      });
      expect(item.designId, 'd1');
      expect(item.orderCount, 3);
      expect(item.designer.id, 'designer-1');
      expect(item.designer.isProDesigner, isTrue);
    });
  });

  group('DesignerProfile', () {
    test('copyWith flips isFollowing + followerCount', () {
      const d = DesignerProfile(
        id: 'designer-1',
        name: 'Nora',
        followerCount: 5,
        isFollowing: false,
      );
      final next = d.copyWith(isFollowing: true, followerCount: 6);
      expect(next.isFollowing, isTrue);
      expect(next.followerCount, 6);
    });
  });
}
