import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/auth/models/user.dart';

/// High-level grouping for admin destinations (keeps navigation scannable).
enum AdminNavGroup {
  /// Dashboard / stats.
  overview,

  /// Accounts and role intake.
  people,

  /// Orders, money, complaints.
  operations,

  /// Content and community safety.
  platform,
}

/// Scope-aware destination entry shown in the admin shell navigation.
class AdminNavItem {
  /// Creates a navigation entry.
  const AdminNavItem({
    required this.labelEn,
    required this.labelAr,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.group,
    this.scope,
  });

  /// English visible label.
  final String labelEn;

  /// Arabic visible label.
  final String labelAr;

  /// Icon shown when unselected.
  final IconData icon;

  /// Icon shown when selected.
  final IconData selectedIcon;

  /// Route path the entry navigates to.
  final String path;

  /// Section this item belongs to.
  final AdminNavGroup group;

  /// Admin scope required to see this entry. `null` = always visible.
  final String? scope;

  /// Localized label for [context]'s locale.
  String label(BuildContext context) =>
      localizedFromContext(context, labelEn, labelAr);
}

/// Canonical admin navigation items.
const List<AdminNavItem> kAdminNavItems = <AdminNavItem>[
  AdminNavItem(
    labelEn: AdminStrings.navOverview,
    labelAr: AdminStrings.navOverviewAr,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/admin/stats',
    group: AdminNavGroup.overview,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navUsers,
    labelAr: AdminStrings.navUsersAr,
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: '/admin/users',
    group: AdminNavGroup.people,
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navRoleRequests,
    labelAr: AdminStrings.navRoleRequestsAr,
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    path: '/admin/role-requests',
    group: AdminNavGroup.people,
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navOrders,
    labelAr: AdminStrings.navOrdersAr,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    path: '/admin/orders',
    group: AdminNavGroup.operations,
    scope: AdminScopes.ordersOversight,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navPayouts,
    labelAr: AdminStrings.navPayoutsAr,
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    path: '/admin/payouts',
    group: AdminNavGroup.operations,
    scope: AdminScopes.payouts,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navComplaints,
    labelAr: AdminStrings.navComplaintsAr,
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
    path: '/admin/complaints',
    group: AdminNavGroup.operations,
    scope: AdminScopes.complaints,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navModeration,
    labelAr: AdminStrings.navModerationAr,
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield,
    path: '/admin/moderation',
    group: AdminNavGroup.platform,
    scope: AdminScopes.moderation,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navNews,
    labelAr: AdminStrings.navNewsAr,
    icon: Icons.newspaper_outlined,
    selectedIcon: Icons.newspaper,
    path: '/admin/news',
    group: AdminNavGroup.platform,
    scope: AdminScopes.news,
  ),
  AdminNavItem(
    labelEn: AdminStrings.navCms,
    labelAr: AdminStrings.navCmsAr,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    path: '/admin/cms',
    group: AdminNavGroup.platform,
    scope: AdminScopes.cms,
  ),
];

/// A labelled group of nav items after scope filtering.
class AdminNavSection {
  const AdminNavSection({
    required this.titleEn,
    required this.titleAr,
    required this.items,
  });

  final String titleEn;
  final String titleAr;
  final List<AdminNavItem> items;
}

/// Filters [kAdminNavItems] to what [user] may access.
List<AdminNavItem> visibleAdminNavItems(User? user) {
  if (user == null) return kAdminNavItems;
  return kAdminNavItems.where((item) {
    if (item.scope == null) return true;
    return user.hasScope(item.scope!);
  }).toList(growable: false);
}

/// Groups visible items into sections (omits empty groups).
List<AdminNavSection> buildAdminNavSections(List<AdminNavItem> items) {
  const order = AdminNavGroup.values;
  final sections = <AdminNavSection>[];
  for (final group in order) {
    final groupItems =
        items.where((i) => i.group == group).toList(growable: false);
    if (groupItems.isEmpty) continue;
    final (titleEn, titleAr) = _groupTitle(group);
    sections.add(
      AdminNavSection(titleEn: titleEn, titleAr: titleAr, items: groupItems),
    );
  }
  return sections;
}

(String, String) _groupTitle(AdminNavGroup group) => switch (group) {
      AdminNavGroup.overview => (
          AdminStrings.navOverview,
          AdminStrings.navOverviewAr,
        ),
      AdminNavGroup.people => (
          AdminStrings.sectionPeople,
          AdminStrings.sectionPeopleAr,
        ),
      AdminNavGroup.operations => (
          AdminStrings.sectionOperations,
          AdminStrings.sectionOperationsAr,
        ),
      AdminNavGroup.platform => (
          AdminStrings.sectionPlatform,
          AdminStrings.sectionPlatformAr,
        ),
    };

/// Resolves the best-matching nav item for [location].
AdminNavItem? adminNavItemForPath(List<AdminNavItem> items, String location) {
  AdminNavItem? best;
  var bestLen = -1;
  for (final item in items) {
    final path = item.path;
    if (location == path || location.startsWith('$path/')) {
      if (path.length > bestLen) {
        bestLen = path.length;
        best = item;
      }
    }
  }
  return best ?? (items.isNotEmpty ? items.first : null);
}

/// Grouped sidebar / drawer used by [AdminShell].
class AdminNavMenu extends StatelessWidget {
  const AdminNavMenu({
    required this.sections,
    required this.currentPath,
    required this.onNavigate,
    required this.onSignOut,
    this.isSuperAdmin = false,
    this.showCloseForDrawer = false,
    super.key,
  });

  final List<AdminNavSection> sections;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final VoidCallback onSignOut;
  final bool isSuperAdmin;
  final bool showCloseForDrawer;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.stone,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.appName, style: AppTextStyles.titleMedium),
                        Text(
                          localizedFromContext(
                            context,
                            AdminStrings.adminConsole,
                            AdminStrings.adminConsoleAr,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.fog,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showCloseForDrawer)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: localizedFromContext(
                        context,
                        AdminStrings.closeMenu,
                        AdminStrings.closeMenuAr,
                      ),
                    ),
                ],
              ),
            ),
            if (isSuperAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: AppColors.goldLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          localizedFromContext(
                            context,
                            AdminStrings.superAdministrator,
                            AdminStrings.superAdministratorAr,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xs,
                      ),
                      child: Text(
                        localizedFromContext(
                          context,
                          section.titleEn,
                          section.titleAr,
                        ),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.fog,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    for (final item in section.items)
                      _AdminNavTile(
                        item: item,
                        selected: currentPath == item.path ||
                            currentPath.startsWith('${item.path}/'),
                        onTap: () => onNavigate(item.path),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSubtle),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.dust),
              title: Text(
                localizedFromContext(
                  context,
                  AdminStrings.signOut,
                  AdminStrings.signOutAr,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  const _AdminNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: selected
            ? AppColors.gold.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 22,
                  color: selected ? AppColors.goldLight : AppColors.dust,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.label(context),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? AppColors.sand : AppColors.dust,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
