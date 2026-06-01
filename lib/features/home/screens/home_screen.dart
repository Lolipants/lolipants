import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/home/logic/ensure_design_gender.dart';
import 'package:lolipants/features/home/providers/home_featured_presets_provider.dart';
import 'package:lolipants/features/home/widgets/hero_banner.dart';
import 'package:lolipants/features/home/widgets/home_browse_shortcuts.dart';
import 'package:lolipants/features/home/widgets/home_featured_sliver_grid.dart';
import 'package:lolipants/features/home/widgets/home_header.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Authenticated home: greeting, AI hero, browse shortcuts, featured grid.
class HomeScreen extends ConsumerWidget {
  /// Creates the home tab screen.
  const HomeScreen({super.key});

  Future<void> _openAiPrompt(BuildContext context, WidgetRef ref) async {
    final gender = await ensureDesignGender(context, ref);
    if (gender == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AiPromptBar(initialGender: gender),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(homeFeaturedPresetsProvider);
    final userGender = ref.watch(userGenderProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ArabesqueBackground(opacity: 0.14),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const HomeHeader(),
                      HeroBanner(onTryNow: () => _openAiPrompt(context, ref)),
                      const SizedBox(height: AppSpacing.xl),
                      const HomeBrowseShortcuts(),
                      const SizedBox(height: AppSpacing.xl),
                      _FeaturedSectionHeader(
                        userGender: userGender,
                        onSeeAll: () => context.go('/browse'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: HomeFeaturedSliverGrid(presets: presets),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedSectionHeader extends StatelessWidget {
  const _FeaturedSectionHeader({
    required this.userGender,
    required this.onSeeAll,
  });

  final String? userGender;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.sectionFeaturedDesigns,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.homeFeaturedSubtitleForGender(userGender),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.fog,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.seeAll,
            style: AppTextStyles.labelGold.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
