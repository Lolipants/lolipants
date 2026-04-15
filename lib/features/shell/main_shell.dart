import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/shared/widgets/bottom_nav_bar.dart';

/// Tab shell with optional music slot above the bottom navigation.
class MainShell extends StatelessWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const MainShell({
    required this.navigationShell,
    super.key,
  });

  /// Indexed stack from go_router for independent tab stacks.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _MusicPlayerSlot(),
          LolipantsBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onChanged: (index) => navigationShell.goBranch(index),
            onDesignTap: () => context.push('/mannequin-selector'),
          ),
        ],
      ),
    );
  }
}

class _MusicPlayerSlot extends StatelessWidget {
  const _MusicPlayerSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.stone,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note, size: 16, color: AppColors.fog.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(
            AppStrings.musicPlayerLabel,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
