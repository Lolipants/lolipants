import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/delivery_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Three-tab shell for delivery-person accounts (Queue / Active / History).
class DeliveryShell extends ConsumerWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const DeliveryShell({required this.navigationShell, super.key});

  /// Indexed stack from go_router for independent tab stacks.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            DeliveryStrings.dashboardTitle,
            DeliveryStrings.dashboardTitleAr,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOutEverywhere();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: localizedFromLocale(
              locale,
              DeliveryStrings.signOut,
              DeliveryStrings.signOutAr,
            ),
          ),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.stone,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: localizedFromLocale(
              locale,
              DeliveryStrings.navQueue,
              DeliveryStrings.navQueueAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: localizedFromLocale(
              locale,
              DeliveryStrings.navActive,
              DeliveryStrings.navActiveAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            selectedIcon: const Icon(Icons.history_toggle_off),
            label: localizedFromLocale(
              locale,
              DeliveryStrings.navHistory,
              DeliveryStrings.navHistoryAr,
            ),
          ),
        ],
      ),
    );
  }
}
