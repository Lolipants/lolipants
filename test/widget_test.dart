import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/app.dart';
import 'package:lolipants/core/constants/app_strings.dart';

void main() {
  testWidgets('LolipantsApp shows design foundation title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LolipantsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.designFoundationTitle), findsOneWidget);
  });
}
