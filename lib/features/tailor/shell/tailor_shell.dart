import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';

/// Three-tab shell for tailor-role users (incoming / active / completed).
class TailorShell extends ConsumerWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const TailorShell({required this.navigationShell, super.key});

  /// Indexed stack from go_router for independent tab stacks.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tailor dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOutEverywhere();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.stone,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Incoming',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Pricing',
          ),
        ],
      ),
    );
  }
}
