import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/features/home/screens/home_screen.dart';

/// Root navigator key for imperative navigation from interceptors.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router (expanded in Phase 2 with auth guards and tabs).
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
