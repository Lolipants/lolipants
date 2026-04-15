import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lolipants/app.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Avoids real HTTP during splash boot so [Future.wait] on splash can finish.
class _TestUnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LolipantsApp shows splash brand on cold start', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(_TestUnauthNotifier.new),
        ],
        child: const LolipantsApp(),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.brandLatin), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();
  });
}
