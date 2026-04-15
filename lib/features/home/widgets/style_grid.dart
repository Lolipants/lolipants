import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/home/widgets/style_card.dart';

/// Section header + grid of traditional style tiles.
class StyleGrid extends StatelessWidget {
  /// Creates the traditional styles block.
  const StyleGrid({super.key});

  static const _items = <({String title, String subtitle, Color color})>[
    (
      title: AppStrings.styleQatariThobe,
      subtitle: AppStrings.originGulf,
      color: Color(0xFF3D2B4F),
    ),
    (
      title: AppStrings.styleSaudiBisht,
      subtitle: AppStrings.originGulf,
      color: Color(0xFF1F4D3A),
    ),
    (
      title: AppStrings.styleUaeKandura,
      subtitle: AppStrings.originGulf,
      color: Color(0xFFB08D3A),
    ),
    (
      title: AppStrings.styleOmaniDishdasha,
      subtitle: AppStrings.originGulf,
      color: Color(0xFF1B4A42),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.sectionTraditionalStyles,
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.sectionTraditionalStylesAr,
                      style: AppTextStyles.arabicBody.copyWith(
                        fontSize: 14,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go('/browse'),
              child: Text(
                '${AppStrings.seeAll} · ${AppStrings.seeAllAr}',
                style: AppTextStyles.labelGold.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.92,
          ),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final e = _items[i];
            return StyleCard(
              title: e.title,
              subtitle: e.subtitle,
              imageColor: e.color,
              onTap: () => context.go('/browse'),
            );
          },
        ),
      ],
    );
  }
}
