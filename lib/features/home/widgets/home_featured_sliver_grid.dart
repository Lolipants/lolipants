import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';

/// Featured design tiles as a [SliverGrid] (parent owns scroll).
class HomeFeaturedSliverGrid extends StatelessWidget {
  const HomeFeaturedSliverGrid({
    required this.presets,
    super.key,
  });

  final List<RegionStylePreset> presets;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: _gap,
          crossAxisSpacing: _gap,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => FeaturedDesignTile(
            preset: presets[index],
            expandToConstraints: true,
          ),
          childCount: presets.length,
        ),
      ),
    );
  }
}
