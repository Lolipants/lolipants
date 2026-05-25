import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/utils/showcase_order.dart';
import 'package:lolipants/features/community/widgets/showcase_feed_section.dart';

/// Builds feed slivers that interleave showcase designs with posts.
List<Widget> buildShowcaseFeedSlivers({
  required String? tagFilter,
  required List<ShowcaseItem> showcaseItems,
}) {
  final filtered = showcaseItemsForFeedTag(showcaseItems, tagFilter);
  if (filtered.isEmpty) return const [];

  if (tagFilter == 'showcase') {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          child: Text(
            'Orderable designs',
            style: AppTextStyles.titleSmall,
          ),
        ),
      ),
      SliverToBoxAdapter(child: ShowcaseFeedGrid(items: filtered)),
    ];
  }

  return [SliverToBoxAdapter(child: ShowcaseFeedStrip(items: filtered))];
}
