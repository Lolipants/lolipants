import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/music/widgets/music_mini_player.dart';
import 'package:lolipants/shared/widgets/bottom_nav_bar.dart';

/// Tab shell with the persistent music mini-player above the bottom nav.
class MainShell extends ConsumerWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const MainShell({
    required this.navigationShell,
    super.key,
  });

  /// Indexed stack from go_router for independent tab stacks.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityTab = ref.watch(communityHubTabIndexProvider);
    final hideGlobalDesignFab = kFeatureCommunity &&
        navigationShell.currentIndex == kCommunityShellBranchIndex &&
        communityTab == 0;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hideGlobalDesignFab
          ? null
          : Semantics(
              label: 'Design button',
              button: true,
              child: FloatingActionButton(
                heroTag: 'design_cta_global',
                elevation: 2,
                focusElevation: 4,
                hoverElevation: 4,
                highlightElevation: 6,
                onPressed: () => context.push('/mannequin-selector'),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.ink,
                child: const Icon(Icons.design_services_outlined),
              ),
            ),
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kFeatureMusicPlayer) const MusicMiniPlayer(),
          LolipantsBottomNavBar(
            shellBranchIndex: navigationShell.currentIndex,
            onShellBranchSelected: navigationShell.goBranch,
          ),
        ],
      ),
    );
  }
}
