import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
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
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    required this.group,
    this.scope,
  });

  /// Visible label.
  final String label;

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
}

/// Canonical admin navigation items.
const List<AdminNavItem> kAdminNavItems = <AdminNavItem>[
  AdminNavItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/admin/stats',
    group: AdminNavGroup.overview,
  ),
  AdminNavItem(
    label: 'Users',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    path: '/admin/users',
    group: AdminNavGroup.people,
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    label: 'Role requests',
    icon: Icons.badge_outlined,
    selectedIcon: Icons.badge,
    path: '/admin/role-requests',
    group: AdminNavGroup.people,
    scope: AdminScopes.usersMgmt,
  ),
  AdminNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
    path: '/admin/orders',
    group: AdminNavGroup.operations,
    scope: AdminScopes.ordersOversight,
  ),
  AdminNavItem(
    label: 'Payouts',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    path: '/admin/payouts',
    group: AdminNavGroup.operations,
    scope: AdminScopes.payouts,
  ),
  AdminNavItem(
    label: 'Complaints',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag,
    path: '/admin/complaints',
    group: AdminNavGroup.operations,
    scope: AdminScopes.complaints,
  ),
  AdminNavItem(
    label: 'Moderation',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield,
    path: '/admin/moderation',
    group: AdminNavGroup.platform,
    scope: AdminScopes.moderation,
  ),
  AdminNavItem(
    label: 'CMS',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    path: '/admin/cms',
    group: AdminNavGroup.platform,
    scope: AdminScopes.cms,
  ),
];

/// A labelled group of nav items after scope filtering.
class AdminNavSection {
  const AdminNavSection({required this.title, required this.items});

  final String title;
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
    sections.add(
      AdminNavSection(title: _groupTitle(group), items: groupItems),
    );
  }
  return sections;
}

String _groupTitle(AdminNavGroup group) => switch (group) {
      AdminNavGroup.overview => 'Overview',
      AdminNavGroup.people => 'People',
      AdminNavGroup.operations => 'Operations',
      AdminNavGroup.platform => 'Platform',
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
                        Text('Lolipants', style: AppTextStyles.titleMedium),
                        Text(
                          'Admin console',
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
                      tooltip: 'Close menu',
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
                      Text(
                        'Super administrator',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.goldLight,
                          fontWeight: FontWeight.w600,
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
                        section.title,
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
              title: Text('Sign out', style: AppTextStyles.bodyMedium),
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
                    item.label,
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
