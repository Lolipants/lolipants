import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/screens/consultations_screen.dart';
import 'package:lolipants/features/community/screens/news_feed_screen.dart';
import 'package:lolipants/features/community/screens/pro_designers_screen.dart';
import 'package:lolipants/features/community/screens/showcase_screen.dart';

/// Top-level Community tab with inner Feed | Showcase | Pros | Consultations
/// segmented sections.
class CommunityScreen extends ConsumerStatefulWidget {
  /// Creates the community hub.
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;
  var _tabListenerAttached = false;

  static const _tabs = <_TabSpec>[
    _TabSpec(label: 'Feed', icon: Icons.dynamic_feed),
    _TabSpec(label: 'Showcase', icon: Icons.shopping_bag_outlined),
    _TabSpec(label: 'Pros', icon: Icons.star_border),
    _TabSpec(label: 'Consult', icon: Icons.forum_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabListenerAttached) {
      _controller.addListener(_syncHubTabIndex);
      _tabListenerAttached = true;
      ref.read(communityHubTabIndexProvider.notifier).state = _controller.index;
    }
  }

  void _syncHubTabIndex() {
    ref.read(communityHubTabIndexProvider.notifier).state = _controller.index;
  }

  @override
  void dispose() {
    if (_tabListenerAttached) {
      _controller.removeListener(_syncHubTabIndex);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.ember,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TabBar(
                  controller: _controller,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.ink,
                  unselectedLabelColor: AppColors.sand,
                  labelStyle: AppTextStyles.titleSmall,
                  unselectedLabelStyle: AppTextStyles.titleSmall,
                  indicator: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  tabs: [
                    for (final tab in _tabs)
                      Tab(
                        icon: Icon(tab.icon, size: 16),
                        iconMargin: EdgeInsets.zero,
                        height: 48,
                        text: tab.label,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  NewsFeedScreen(),
                  ShowcaseScreen(),
                  ProDesignersScreen(),
                  ConsultationsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.label, required this.icon});
  final String label;
  final IconData icon;
}
