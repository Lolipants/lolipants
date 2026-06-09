import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/features/editor/data/editor_design_restore.dart';

void main() {
  group('isAiHomeDraftFromRenderMetadata', () {
    test('true when home draft without refined look', () {
      expect(
        isAiHomeDraftFromRenderMetadata(const {'aiHomeDraft': true}),
        isTrue,
      );
    });

    test('false when home draft already has refined look', () {
      expect(
        isAiHomeDraftFromRenderMetadata(const {
          'aiHomeDraft': true,
          'aiRefinedLookUrl': 'https://cdn.example/look.png',
        }),
        isFalse,
      );
    });

    test('false when not a home draft', () {
      expect(isAiHomeDraftFromRenderMetadata(const {}), isFalse);
    });
  });
}
