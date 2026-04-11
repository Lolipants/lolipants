import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Bottom navigation: Home, Browse, Orders, Profile (Phase 1 scope).
class LolipantsBottomNavBar extends StatelessWidget {
  /// Creates the tab bar with the active index.
  const LolipantsBottomNavBar({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  /// Selected tab index (0–3).
  final int currentIndex;

  /// Notifies when a tab is tapped.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = <_NavSpec>[
      _NavSpec(
        labelEn: AppStrings.navHome,
        labelAr: AppStrings.navHomeAr,
        icon: Icons.home_outlined,
      ),
      _NavSpec(
        labelEn: AppStrings.navBrowse,
        labelAr: AppStrings.navBrowseAr,
        icon: Icons.diamond_outlined,
      ),
      _NavSpec(
        labelEn: AppStrings.navOrders,
        labelAr: AppStrings.navOrdersAr,
        icon: Icons.receipt_long_outlined,
      ),
      _NavSpec(
        labelEn: AppStrings.navProfile,
        labelAr: AppStrings.navProfileAr,
        icon: Icons.person_outline,
      ),
    ];

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
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: _NavEntry(
                  spec: items[index],
                  selected: selected,
                  onTap: () => onChanged(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(spec.icon, color: color, size: 22),
          const SizedBox(height: 2),
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
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            width: selected ? 22 : 6,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: selected ? 1 : 0.22),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }
}
