import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';

/// Helpers to parse `#RRGGBB` hex strings.
Color parseHexColour(String? value, {Color fallback = AppColors.gold}) {
  if (value == null || value.isEmpty) return fallback;
  var hex = value.trim().replaceAll('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  final parsed = int.tryParse(hex, radix: 16);
  return parsed != null ? Color(parsed) : fallback;
}

/// Showcase item card used on the marketplace grid and designer profile.
class ShowcaseCard extends StatelessWidget {
  /// Creates a showcase card.
  const ShowcaseCard({
    required this.item,
    required this.onTap,
    required this.onOrder,
    this.compact = false,
    super.key,
  });

  /// Item to render.
  final ShowcaseItem item;

  /// Called when the card itself is tapped (opens designer profile).
  final VoidCallback onTap;

  /// Called when the "Order this" button is tapped.
  final VoidCallback onOrder;

  /// Tighter footer spacing for horizontal feed strips.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColour(item.primaryColour);
    final accent = parseHexColour(item.accentColour, fallback: primary);
    final footerPadding = compact
        ? const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.sm,
          )
        : const EdgeInsets.all(AppSpacing.md);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primary, accent],
                        ),
                      ),
                    ),
                    if (item.previewImageUrl != null)
                      CachedNetworkImage(
                        imageUrl: item.previewImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: footerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.garmentType,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: compact ? 2 : 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${localizedFromContext(context, CommunityStrings.byDesigner, CommunityStrings.byDesignerAr)} ${item.designer.name}',
                          style: compact
                              ? AppTextStyles.bodySmall
                              : AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.designer.isProDesigner)
                        const Icon(
                          Icons.verified,
                          color: AppColors.gold,
                          size: 14,
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onOrder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: compact ? 4 : 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        localizedFromContext(
                          context,
                          CommunityStrings.orderThis,
                          CommunityStrings.orderThisAr,
                        ),
                        style: compact
                            ? AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gold,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
