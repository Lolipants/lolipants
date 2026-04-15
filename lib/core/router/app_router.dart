import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/screens/forgot_password_screen.dart';
import 'package:lolipants/features/auth/screens/login_screen.dart';
import 'package:lolipants/features/auth/screens/signup_screen.dart';
import 'package:lolipants/features/browse/screens/browse_screen.dart';
import 'package:lolipants/features/browse/screens/mannequin_selector_screen.dart';
import 'package:lolipants/features/community/screens/community_screen.dart';
import 'package:lolipants/features/editor/screens/design_preview_360_screen.dart';
import 'package:lolipants/features/editor/screens/editor_screen.dart';
import 'package:lolipants/features/home/screens/home_screen.dart';
import 'package:lolipants/features/onboarding/screens/onboarding_screen.dart';
import 'package:lolipants/features/orders/screens/order_detail_screen.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/screens/order_summary_screen.dart';
import 'package:lolipants/features/orders/screens/orders_screen.dart';
import 'package:lolipants/features/profile/screens/my_designs_screen.dart';
import 'package:lolipants/features/profile/screens/my_measurements_screen.dart';
import 'package:lolipants/features/profile/screens/profile_screen.dart';
import 'package:lolipants/features/sizing/screens/ai_measurement_screen.dart';
import 'package:lolipants/features/sizing/screens/manual_size_screen.dart';
import 'package:lolipants/features/sizing/screens/sizing_method_screen.dart';
import 'package:lolipants/features/sizing/screens/workshop_booking_screen.dart';
import 'package:lolipants/features/shell/main_shell.dart';
import 'package:lolipants/features/splash/screens/splash_screen.dart';

/// Root navigator key for imperative navigation from interceptors.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isShellLocation(String location) {
  const roots = ['/home', '/browse', '/orders', '/community', '/profile'];
  for (final root in roots) {
    if (location == root || location.startsWith('$root/')) {
      return true;
    }
  }
  return false;
}

bool _isProtectedLocation(String location) {
  if (_isShellLocation(location)) return true;
  if (location == '/sizing' || location.startsWith('/sizing/')) return true;
  if (location == '/order/summary' || location.startsWith('/order/')) return true;
  return location == '/editor' ||
      location.startsWith('/editor/') ||
      location == '/mannequin-selector';
}

String? _redirectLogic(AsyncValue<AuthState> auth, String location) {
  if (auth.isLoading) {
    if (location != '/') {
      return '/';
    }
    return null;
  }
  if (auth.hasError) {
    if (_isProtectedLocation(location)) {
      return '/login';
    }
    return null;
  }
  final state = auth.value;
  if (state is AuthAuthenticated) {
    if (location == '/login' || location == '/signup') {
      return '/home';
    }
    return null;
  }
  if (_isProtectedLocation(location)) {
    return '/login';
  }
  return null;
}

/// GoRouter instance wired to Riverpod auth refresh.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
    refresh.value++;
  });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      return _redirectLogic(auth, state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot',
        name: 'forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/sizing',
        name: 'sizingMethod',
        builder: (context, state) => const SizingMethodScreen(),
        routes: [
          GoRoute(
            path: 'ai',
            name: 'sizingAi',
            builder: (context, state) => const AiMeasurementScreen(),
          ),
          GoRoute(
            path: 'manual',
            name: 'sizingManual',
            builder: (context, state) => const ManualSizeScreen(),
          ),
          GoRoute(
            path: 'workshop',
            name: 'sizingWorkshop',
            builder: (context, state) => const WorkshopBookingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/mannequin-selector',
        name: 'mannequinSelector',
        builder: (context, state) => const MannequinSelectorScreen(),
      ),
      GoRoute(
        path: '/order/summary',
        name: 'orderSummary',
        builder: (context, state) {
          final draft = state.extra is OrderDesignDraft
              ? state.extra! as OrderDesignDraft
              : null;
          return OrderSummaryScreen(designDraft: draft);
        },
      ),
      GoRoute(
        path: '/editor',
        name: 'editor',
        builder: (context, state) {
          final mannequinId = state.extra is String ? state.extra! as String : null;
          return EditorScreen(initialMannequinId: mannequinId);
        },
        routes: [
          GoRoute(
            path: 'preview',
            name: 'editorPreview',
            builder: (context, state) => const DesignPreview360Screen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                name: 'browse',
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: 'detail/:orderId',
                    name: 'orderDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['orderId']!;
                      return OrderDetailScreen(orderId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                name: 'community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'designs',
                    name: 'myDesigns',
                    builder: (context, state) => const MyDesignsScreen(),
                  ),
                  GoRoute(
                    path: 'measurements',
                    name: 'myMeasurements',
                    builder: (context, state) => const MyMeasurementsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
