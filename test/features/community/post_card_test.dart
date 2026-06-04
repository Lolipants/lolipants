import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/widgets/post_card.dart';

Post _makePost({
  ReactionType? reaction,
  int reactionCount = 3,
  int commentCount = 2,
  List<String> tags = const ['thobe'],
  List<String> imageUrls = const [],
  bool verified = true,
}) {
  return Post(
    id: 'p1',
    authorId: 'author-1',
    authorName: 'Nora Designer',
    isVerifiedDesigner: verified,
    body: 'Fresh drop on the showcase.',
    imageUrls: imageUrls,
    tags: tags,
    reactionCount: reactionCount,
    commentCount: commentCount,
    currentUserReaction: reaction,
    postedAt: DateTime(2026, 4, 15, 10),
  );
}

void main() {
  testWidgets('renders author, body, tags, reaction/comment counts',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: _makePost(),
              onToggleReaction: (_) {},
              onOpenDetail: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nora Designer'), findsOneWidget);
    expect(find.text('Fresh drop on the showcase.'), findsOneWidget);
    expect(find.text('#thobe'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsWidgets);
  });

  testWidgets('renders filled heart icon when the viewer has loved the post',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: _makePost(reaction: ReactionType.love),
              onToggleReaction: (_) {},
              onOpenDetail: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('tapping the heart fires onToggleReaction with love',
      (tester) async {
    ReactionType? capturedType;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: _makePost(),
              onToggleReaction: (t) => capturedType = t,
              onOpenDetail: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(capturedType, ReactionType.love);
  });

  testWidgets('single image uses portrait aspect ratio without cropping',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                PostCard(
                  post: _makePost(imageUrls: ['https://example.com/look.png']),
                  onToggleReaction: (_) {},
                  onOpenDetail: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final aspect = tester.widget<AspectRatio>(find.byType(AspectRatio));
    expect(aspect.aspectRatio, closeTo(3 / 4, 0.001));
  });

  testWidgets('tapping the body fires onOpenDetail', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: _makePost(),
              onToggleReaction: (_) {},
              onOpenDetail: () => opens += 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Fresh drop on the showcase.'));
    await tester.pump();
    expect(opens, 1);
  });
}
