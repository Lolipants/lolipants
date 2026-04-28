import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Bottom navigation for the main customer shell: maps each visible tab to a
/// [StatefulNavigationShell] branch index (0=home, 1=browse, 2=orders,
/// 3=community, 4=profile). When [kFeatureCommunity] is false, community
/// is omitted and four tabs target branches `0,1,2,4`.
class LolipantsBottomNavBar extends StatelessWidget {
  /// Creates the tab bar for the current [shellBranchIndex].
  const LolipantsBottomNavBar({
    required this.shellBranchIndex,
    required this.onShellBranchSelected,
    super.key,
  });

  /// Active shell branch index from [StatefulNavigationShell.currentIndex].
  final int shellBranchIndex;

  /// Selects a shell branch (same as [StatefulNavigationShell.goBranch]).
  final ValueChanged<int> onShellBranchSelected;

  static List<_NavDef> _defs() {
    const home = _NavSpec(
      labelEn: AppStrings.navHome,
      labelAr: AppStrings.navHomeAr,
      icon: Icons.home_outlined,
    );
    const browse = _NavSpec(
      labelEn: AppStrings.navBrowse,
      labelAr: AppStrings.navBrowseAr,
      icon: Icons.diamond_outlined,
    );
    const orders = _NavSpec(
      labelEn: AppStrings.navOrders,
      labelAr: AppStrings.navOrdersAr,
      icon: Icons.receipt_long_outlined,
    );
    const community = _NavSpec(
      labelEn: AppStrings.navCommunity,
      labelAr: AppStrings.navCommunityAr,
      icon: Icons.people_outline,
    );
    const profile = _NavSpec(
      labelEn: AppStrings.navProfile,
      labelAr: AppStrings.navProfileAr,
      icon: Icons.person_outline,
    );
    if (kFeatureCommunity) {
      return const [
        _NavDef(0, home),
        _NavDef(1, browse),
        _NavDef(2, orders),
        _NavDef(3, community),
        _NavDef(4, profile),
      ];
    }
    return const [
      _NavDef(0, home),
      _NavDef(1, browse),
      _NavDef(2, orders),
      _NavDef(4, profile),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final defs = _defs();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.xxl + AppSpacing.xxl + AppSpacing.md,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(defs.length, (i) {
              final def = defs[i];
              final selected = shellBranchIndex == def.branchIndex;
              return Expanded(
                child: _NavEntry(
                  spec: def.spec,
                  selected: selected,
                  onTap: () => onShellBranchSelected(def.branchIndex),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  const _NavDef(this.branchIndex, this.spec);

  final int branchIndex;
  final _NavSpec spec;
}

class _NavSpec {
  /// Tab metadata.
  const _NavSpec({
    required this.labelEn,
    required this.labelAr,
    required this.icon,
  });

  /// English label.
  final String labelEn;

  /// Arabic label.
  final String labelAr;

  /// Leading icon data.
  final IconData icon;
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.fog;

    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      child: Semantics(
        label: '${spec.labelEn} tab',
        button: true,
        selected: selected,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, color: color, size: 22),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                spec.labelAr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.arabicLabel.copyWith(
                  fontSize: 9,
                  color: color,
                ),
              ),
              Text(
                spec.labelEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelGold.copyWith(
                  fontSize: 8,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: selected ? 22 : 6,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: selected ? 1 : 0.22),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
