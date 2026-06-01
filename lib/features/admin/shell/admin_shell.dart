import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/admin/widgets/admin_nav_menu.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

export 'package:lolipants/features/admin/widgets/admin_nav_menu.dart'
    show AdminNavItem, kAdminNavItems;

/// Shell chrome around every admin route.
///
/// Narrow layouts use a grouped [Drawer] (no crowded bottom bar). Wide layouts
/// show a persistent sidebar with the same grouped menu.
class AdminShell extends ConsumerStatefulWidget {
  /// Wraps [child] with the admin navigation chrome.
  const AdminShell({required this.child, super.key});

  /// Routed child provided by go_router's [ShellRoute].
  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  static const double _sidebarBreakpoint = 900;
  static const double _sidebarWidth = 272;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final localeKey = ref.watch(settingsLocaleProvider).languageCode;
    final auth = ref.watch(authProvider).value;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final items = visibleAdminNavItems(user);
    final sections = buildAdminNavSections(items);
    final location = GoRouterState.of(context).uri.path;
    final current = adminNavItemForPath(items, location);
    final isWide = MediaQuery.sizeOf(context).width >= _sidebarBreakpoint;

    void navigate(String path) {
      if (location != path) context.go(path);
      if (!isWide) _scaffoldKey.currentState?.closeDrawer();
    }

    Future<void> signOut() async {
      await ref.read(authProvider.notifier).signOutEverywhere();
      if (context.mounted) context.go('/login');
    }

    final menu = AdminNavMenu(
      sections: sections,
      currentPath: location,
      onNavigate: navigate,
      onSignOut: signOut,
      isSuperAdmin: user?.isSuperAdmin ?? false,
      showCloseForDrawer: !isWide,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.ink,
      drawer: isWide ? null : Drawer(width: _sidebarWidth, child: menu),
      appBar: AppBar(
        backgroundColor: AppColors.stone,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current?.label(context) ??
                  localized(ref, AdminStrings.adminTitle, AdminStrings.adminTitleAr),
              style: AppTextStyles.titleMedium,
            ),
            if (current != null)
              Text(
                _sectionLabelFor(ref, current),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
              ),
          ],
        ),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: localized(
                  ref,
                  AdminStrings.openMenu,
                  AdminStrings.openMenuAr,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        automaticallyImplyLeading: !isWide,
        actions: [
          if (isWide)
            IconButton(
              onPressed: signOut,
              icon: const Icon(Icons.logout),
              tooltip: localized(
                ref,
                AdminStrings.signOut,
                AdminStrings.signOutAr,
              ),
            ),
        ],
      ),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: _sidebarWidth, child: menu),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey<String>('admin_body_$localeKey'),
                    child: widget.child,
                  ),
                ),
              ],
            )
          : KeyedSubtree(
              key: ValueKey<String>('admin_body_$localeKey'),
              child: widget.child,
            ),
    );
  }

  String _sectionLabelFor(WidgetRef ref, AdminNavItem item) =>
      switch (item.group) {
        AdminNavGroup.overview => localized(
            ref,
            AdminStrings.navOverview,
            AdminStrings.navOverviewAr,
          ),
        AdminNavGroup.people => localized(
            ref,
            AdminStrings.sectionPeople,
            AdminStrings.sectionPeopleAr,
          ),
        AdminNavGroup.operations => localized(
            ref,
            AdminStrings.sectionOperations,
            AdminStrings.sectionOperationsAr,
          ),
        AdminNavGroup.platform => localized(
            ref,
            AdminStrings.sectionPlatform,
            AdminStrings.sectionPlatformAr,
          ),
      };
}
