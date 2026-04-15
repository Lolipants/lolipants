import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/widgets/country_card.dart';
import 'package:lolipants/features/browse/widgets/featured_strip.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Region browse hub (Phase 2C).
class BrowseScreen extends StatelessWidget {
  /// Creates the browse tab.
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            AppStrings.browseHeaderAr,
                            style: AppTextStyles.arabicLabel.copyWith(
                              fontSize: 13,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        Text(
                          AppStrings.browseHeader,
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          AppStrings.chooseYourRegion,
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _RegionPillsRow(),
                        const SizedBox(height: AppSpacing.xl),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.95,
                          children: const [
                            CountryCard.qatar(),
                            CountryCard.saudi(),
                            CountryCard.uae(),
                            CountryCard.oman(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const FeaturedStrip(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionPillsRow extends StatefulWidget {
  const _RegionPillsRow();

  @override
  State<_RegionPillsRow> createState() => _RegionPillsRowState();
}

class _RegionPillsRowState extends State<_RegionPillsRow> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['Gulf', 'Modern', 'Levant'];
    return Row(
      children: List.generate(labels.length, (index) {
        final on = index == _i;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => setState(() => _i = index),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: on ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: on ? Colors.transparent : AppColors.borderDefault,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  labels[index],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: on ? AppColors.ink : AppColors.fog,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
