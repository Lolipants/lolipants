import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Compact Male / Female / Kids row plus traditional, accessories, and casual.
class HomeCategoryShortcuts extends StatelessWidget {
  const HomeCategoryShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final genders = <_GenderShortcut>[
      if (kFeatureMens)
        _GenderShortcut(
          slug: 'men',
          label: AppStrings.homeCategoryMen,
          icon: Icons.man_outlined,
        ),
      _GenderShortcut(
        slug: 'women',
        label: AppStrings.homeCategoryWomen,
        icon: Icons.woman_outlined,
      ),
      if (kFeatureMens)
        _GenderShortcut(
          slug: 'kids',
          label: AppStrings.homeCategoryKids,
          icon: Icons.child_care_outlined,
        ),
    ];

    final lanes = <_LaneShortcut>[
      _LaneShortcut(
        icon: Icons.public_outlined,
        label: AppStrings.homeTraditionalTitle,
        onTap: () => context.go('/browse'),
      ),
      _LaneShortcut(
        icon: Icons.diamond_outlined,
        label: AppStrings.homeAccessoriesTitle,
        onTap: () => context.push('/browse/c/accessories'),
      ),
      if (kFeatureCasual)
        _LaneShortcut(
          icon: Icons.checkroom_outlined,
          label: AppStrings.homeCasualTitle,
          onTap: () => context.push('/browse/c/casual'),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.homeShopByGender,
          style: AppTextStyles.labelGold.copyWith(fontSize: 10),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < genders.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GenderTile(
                  shortcut: genders[i],
                  onTap: () => context.push('/browse/c/${genders[i].slug}'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < lanes.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                _LaneChip(lane: lanes[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderShortcut {
  const _GenderShortcut({
    required this.slug,
    required this.label,
    required this.icon,
  });

  final String slug;
  final String label;
  final IconData icon;
}

class _LaneShortcut {
  const _LaneShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.shortcut,
    required this.onTap,
  });

  final _GenderShortcut shortcut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stone.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(shortcut.icon, color: AppColors.gold, size: 26),
              const SizedBox(height: AppSpacing.xs),
              Text(
                shortcut.label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaneChip extends StatelessWidget {
  const _LaneChip({required this.lane});

  final _LaneShortcut lane;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(lane.icon, size: 18, color: AppColors.gold),
      label: Text(lane.label),
      labelStyle: AppTextStyles.bodySmall,
      backgroundColor: AppColors.ember.withValues(alpha: 0.9),
      side: const BorderSide(color: AppColors.borderSubtle),
      onPressed: lane.onTap,
    );
  }
}
