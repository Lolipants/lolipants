import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
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
    super.key,
  });

  /// Item to render.
  final ShowcaseItem item;

  /// Called when the card itself is tapped (opens designer profile).
  final VoidCallback onTap;

  /// Called when the "Order this" button is tapped.
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final primary = parseHexColour(item.primaryColour);
    final accent = parseHexColour(item.accentColour, fallback: primary);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, accent],
                    ),
                  ),
                  child: item.previewImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.previewImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.garmentType,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'by ${item.designer.name}',
                          style: AppTextStyles.bodyMedium,
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
                  const SizedBox(height: AppSpacing.sm),
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
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                      child: const Text('Order this'),
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
