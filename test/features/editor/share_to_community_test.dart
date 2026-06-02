import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Avoids real HTTP during router construction.
class _TestUnauthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthUnauthenticated();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    '/community/new-post and /community/posts/:id render on the root navigator',
    () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_TestUnauthNotifier.new),
          settingsLocaleProvider.overrideWith((ref) => const Locale('en')),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);

      GoRoute? findRoute(List<RouteBase> routes, String path) {
        for (final r in routes) {
          if (r is GoRoute && r.path == path) return r;
          final nested = findRoute(r.routes, path);
          if (nested != null) return nested;
        }
        return null;
      }

      final newPost = findRoute(router.configuration.routes, 'new-post');
      final postDetail =
          findRoute(router.configuration.routes, 'posts/:postId');

      expect(newPost, isNotNull, reason: 'new-post route should exist');
      expect(postDetail, isNotNull, reason: 'posts/:postId route should exist');

      // The crash fix hinges on these child routes being rendered on the
      // root navigator so they don't collide with the shell's page keys.
      expect(newPost!.parentNavigatorKey, rootNavigatorKey);
      expect(postDetail!.parentNavigatorKey, rootNavigatorKey);
    },
  );
}
