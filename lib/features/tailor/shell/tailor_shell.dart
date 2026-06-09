import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/tailor_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Three-tab shell for tailor-role users (incoming / active / completed).
class TailorShell extends ConsumerWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const TailorShell({required this.navigationShell, super.key});

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
            TailorStrings.dashboardTitle,
            TailorStrings.dashboardTitleAr,
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
              TailorStrings.signOut,
              TailorStrings.signOutAr,
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
            icon: const Icon(Icons.inbox_outlined),
            selectedIcon: const Icon(Icons.inbox),
            label: localizedFromLocale(
              locale,
              TailorStrings.navIncoming,
              TailorStrings.navIncomingAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.price_change_outlined),
            selectedIcon: const Icon(Icons.price_change),
            label: localizedFromLocale(
              locale,
              TailorStrings.navOffers,
              TailorStrings.navOffersAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.construction_outlined),
            selectedIcon: const Icon(Icons.construction),
            label: localizedFromLocale(
              locale,
              TailorStrings.navActive,
              TailorStrings.navActiveAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: const Icon(Icons.check_circle),
            label: localizedFromLocale(
              locale,
              TailorStrings.navCompleted,
              TailorStrings.navCompletedAr,
            ),
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: localizedFromLocale(
              locale,
              TailorStrings.navPricing,
              TailorStrings.navPricingAr,
            ),
          ),
        ],
      ),
    );
  }
}
