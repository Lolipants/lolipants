import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/orders/models/accessory_order_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Accessory product detail with buy-now CTA.
class AccessoryDetailScreen extends ConsumerWidget {
  const AccessoryDetailScreen({required this.accessory, super.key});

  final Accessory accessory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = accessory.descriptionEn?.trim();

    return Scaffold(
      appBar: AppBar(title: Text(accessory.labelEn)),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: accessory.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(accessory.labelEn, style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  accessory.labelAr,
                  style: AppTextStyles.arabicLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${accessory.salePrice.round()} QAR',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.gold),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(description, style: AppTextStyles.bodyMedium),
              ],
              if (accessory.descriptionAr != null &&
                  accessory.descriptionAr!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    accessory.descriptionAr!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (kFeatureAccessories)
                LolipantsButton(
                  label: 'Buy now',
                  onPressed: () {
                    startAccessoryCheckoutDraft(
                      ref,
                      AccessoryOrderDraft(
                        accessoryId: accessory.id,
                        accessoryLabel: accessory.labelEn,
                        accessoryImageUrl: accessory.imageUrl,
                        category: accessory.category,
                        salePrice: accessory.salePrice,
                      ),
                    );
                    context.push('/order/accessory-summary');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
