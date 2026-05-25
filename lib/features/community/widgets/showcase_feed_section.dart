import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/utils/showcase_order.dart';
import 'package:lolipants/features/community/widgets/showcase_card.dart';

/// Horizontal showcase strip for the community feed ("All" and garment tags).
class ShowcaseFeedStrip extends ConsumerWidget {
  const ShowcaseFeedStrip({
    required this.items,
    super.key,
  });

  final List<ShowcaseItem> items;

  static const _cardWidth = 168.0;
  static const _cardHeight = 292.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Text('From Showcase', style: AppTextStyles.titleSmall),
        ),
        SizedBox(
          height: _cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: ShowcaseCard(
                  item: item,
                  compact: true,
                  onTap: () =>
                      context.push('/community/designer/${item.designer.id}'),
                  onOrder: () =>
                      orderShowcaseItem(ref, GoRouter.of(context), item),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(color: AppColors.borderSubtle, height: 1),
      ],
    );
  }
}

/// Two-column showcase grid embedded in the feed (Showcase tag filter).
class ShowcaseFeedGrid extends ConsumerWidget {
  const ShowcaseFeedGrid({
    required this.items,
    super.key,
  });

  final List<ShowcaseItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            'No showcase designs yet. Publish from My Designs.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final crossCount = MediaQuery.sizeOf(context).width >= 800 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: kShowcaseGridAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ShowcaseCard(
          item: item,
          onTap: () => context.push('/community/designer/${item.designer.id}'),
          onOrder: () => orderShowcaseItem(ref, GoRouter.of(context), item),
        );
      },
    );
  }
}
