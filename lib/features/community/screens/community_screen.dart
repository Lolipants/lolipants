import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
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
    _TabSpec(
      en: CommunityStrings.tabFeed,
      ar: CommunityStrings.tabFeedAr,
      icon: Icons.dynamic_feed,
    ),
    _TabSpec(
      en: CommunityStrings.tabShowcase,
      ar: CommunityStrings.tabShowcaseAr,
      icon: Icons.shopping_bag_outlined,
    ),
    _TabSpec(
      en: CommunityStrings.tabPros,
      ar: CommunityStrings.tabProsAr,
      icon: Icons.star_border,
    ),
    _TabSpec(
      en: CommunityStrings.tabConsult,
      ar: CommunityStrings.tabConsultAr,
      icon: Icons.forum_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialTab = 0;
    _controller = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabListenerAttached) {
      _controller.addListener(_syncHubTabIndex);
      _tabListenerAttached = true;
    }
    final hubTab = ref.read(communityHubTabIndexProvider);
    if (_controller.index != hubTab) {
      _controller.index = hubTab;
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
    ref.listen<int>(communityHubTabIndexProvider, (previous, next) {
      if (_controller.index != next) {
        _controller.animateTo(next);
      }
    });

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
                        text: localizedFromContext(context, tab.en, tab.ar),
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
  const _TabSpec({required this.en, required this.ar, required this.icon});
  final String en;
  final String ar;
  final IconData icon;
}
