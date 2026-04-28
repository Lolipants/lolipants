import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/auth/models/user.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';

/// Scope-aware destination entry shown in the admin shell navigation.
class AdminNavItem {
  /// Creates a navigation entry.
  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.scope,
  });

  /// Visible label.
  final String label;

  /// Icon shown when unselected.
  final IconData icon;

  /// Icon shown when selected.
  final IconData selectedIcon;

  /// Route path the entry navigates to.
  final String path;

  /// Admin scope required to see this tab. Use [AdminScopes.superAdmin]-only
  /// semantics with `null` to mean "always show".
  final String? scope;
}

/// Canonical admin navigation items, in the order they appear. Scope filtering
/// is applied in [AdminShell] based on `user.hasScope(item.scope)`.
const List<AdminNavItem> kAdminNavItems = <AdminNavItem>[
  AdminNavItem(
    label: 'Stats',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/admin/stats',
    scope: null,
  ),
  AdminNavItem(
    label: 'Users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: '/admin/users',
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    label: 'Role requests',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    path: '/admin/role-requests',
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    path: '/admin/orders',
    scope: AdminScopes.ordersOversight,
  ),
  AdminNavItem(
    label: 'Payouts',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    path: '/admin/payouts',
    scope: AdminScopes.payouts,
  ),
  AdminNavItem(
    label: 'Moderation',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield,
    path: '/admin/moderation',
    scope: AdminScopes.moderation,
  ),
  AdminNavItem(
    label: 'CMS',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    path: '/admin/cms',
    scope: AdminScopes.cms,
  ),
  AdminNavItem(
    label: 'Complaints',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
    path: '/admin/complaints',
    scope: AdminScopes.complaints,
  ),
];

/// Shell chrome around every admin route. Uses a [NavigationRail] on wide
/// layouts and a [BottomNavigationBar] on narrow layouts. Tabs are filtered to
/// match [User.adminScopes] so a scoped admin only sees what they can touch.
class AdminShell extends ConsumerWidget {
  /// Wraps [child] with the admin navigation chrome.
  const AdminShell({required this.child, super.key});

  /// Routed child provided by go_router's [ShellRoute].
  final Widget child;

  List<AdminNavItem> _visibleItems(User user) {
    return kAdminNavItems.where((item) {
      if (item.scope == null) return true;
      return user.hasScope(item.scope!);
    }).toList(growable: false);
  }

  int _currentIndex(List<AdminNavItem> items, String location) {
    var index = -1;
    var bestLen = -1;
    for (var i = 0; i < items.length; i++) {
      final path = items[i].path;
      if (location == path || location.startsWith('$path/')) {
        if (path.length > bestLen) {
          bestLen = path.length;
          index = i;
        }
      }
    }
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).value;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final items = user == null ? kAdminNavItems : _visibleItems(user);
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndex(items, location);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    void go(int index) {
      final target = items[index].path;
      if (location != target) context.go(target);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
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
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.stone,
                  selectedIndex: currentIndex,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              backgroundColor: AppColors.stone,
              selectedIndex: currentIndex,
              onDestinationSelected: go,
              destinations: [
                for (final item in items)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            ),
    );
  }
}
