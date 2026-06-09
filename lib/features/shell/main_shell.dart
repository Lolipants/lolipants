import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';
import 'package:lolipants/features/music/widgets/music_mini_player.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/bottom_nav_bar.dart';
import 'package:lolipants/shared/widgets/labeled_floating_action_button.dart';

/// Tab shell with the persistent music mini-player above the bottom nav.
class MainShell extends ConsumerStatefulWidget {
  /// Creates the shell wrapping a [StatefulNavigationShell].
  const MainShell({
    required this.navigationShell,
    super.key,
  });

  /// Indexed stack from go_router for independent tab stacks.
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    final previous = oldWidget.navigationShell.currentIndex;
    if (index == kHomeShellBranchIndex && index != previous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(homeFlowSelectionProvider.notifier).resetToStart();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsLocaleProvider);
    final communityTab = ref.watch(communityHubTabIndexProvider);
    final shellIndex = widget.navigationShell.currentIndex;
    final hideOnCommunityFeed = kFeatureCommunity &&
        shellIndex == kCommunityShellBranchIndex &&
        communityTab == 0;
    final hideGlobalDesignFab =
        shellIndex == kHomeShellBranchIndex || hideOnCommunityFeed;

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hideGlobalDesignFab
          ? null
          : LabeledFloatingActionButton(
              heroTag: 'design_cta_global',
              icon: Icons.design_services_outlined,
              labelEn: AppStrings.fabDesign,
              labelAr: AppStrings.fabDesignAr,
              onPressed: () => openDesignMannequinFlow(context),
            ),
      body: KeyedSubtree(
        key: ValueKey<String>(
          'main_shell_${ref.watch(settingsLocaleProvider).languageCode}',
        ),
        child: widget.navigationShell,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kFeatureMusicPlayer) const MusicMiniPlayer(),
          LolipantsBottomNavBar(
            shellBranchIndex: shellIndex,
            onShellBranchSelected: widget.navigationShell.goBranch,
          ),
        ],
      ),
    );
  }
}
