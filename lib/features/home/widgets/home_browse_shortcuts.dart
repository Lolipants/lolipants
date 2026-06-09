import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/features/home/widgets/frosted_shortcut_chip.dart';

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
          FrostedShortcutChip(
            icon: lane.icon,
            label: lane.label,
            onTap: lane.onTap,
          ),
      ],
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
