import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';

/// Quick browse lanes (no gender tiles — profile gender drives the feed).
class HomeBrowseShortcuts extends StatelessWidget {
  const HomeBrowseShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final lanes = <_Lane>[
      _Lane(
        icon: Icons.grid_view_rounded,
        label: AppStrings.homeExploreAll,
        onTap: () => context.go('/browse'),
      ),
      _Lane(
        icon: Icons.public_outlined,
        label: AppStrings.homeTraditionalTitle,
        onTap: () => context.go('/browse'),
      ),
      _Lane(
        icon: Icons.diamond_outlined,
        label: AppStrings.homeAccessoriesTitle,
        onTap: () => context.push('/browse/c/accessories'),
      ),
      if (kFeatureCasual)
        _Lane(
          icon: Icons.checkroom_outlined,
          label: AppStrings.homeCasualTitle,
          onTap: () => context.push('/browse/c/casual'),
        ),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final lane in lanes)
          _FrostedShortcutChip(
            icon: lane.icon,
            label: lane.label,
            onTap: lane.onTap,
          ),
      ],
    );
  }
}

class _FrostedShortcutChip extends StatelessWidget {
  const _FrostedShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.32),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: AppColors.gold),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.sand,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Lane {
  const _Lane({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
