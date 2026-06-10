import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/l10n/localized_label.dart';
import 'package:lolipants/features/orders/models/wedding_order_draft.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/widgets/wedding_dress_hero.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Dress detail — fulfillment chosen earlier; rental days + checkout here.
class WeddingDressDetailScreen extends ConsumerStatefulWidget {
  const WeddingDressDetailScreen({
    required this.dress,
    required this.fulfillment,
    super.key,
  });

  final WeddingDress dress;
  final WeddingFulfillment fulfillment;

  @override
  ConsumerState<WeddingDressDetailScreen> createState() =>
      _WeddingDressDetailScreenState();
}

class _WeddingDressDetailScreenState
    extends ConsumerState<WeddingDressDetailScreen> {
  int _rentalDays = 3;

  @override
  Widget build(BuildContext context) {
    if (!kFeatureWeddingFlow) {
      return const Scaffold(
        body: Center(child: Text('Wedding flow is not available')),
      );
    }

    final locale = ref.watch(settingsLocaleProvider);
    final dress = widget.dress;
    final fulfillment = widget.fulfillment;
    final dressLabel = localizedLabel(
      locale,
      en: dress.labelEn,
      ar: dress.labelAr.trim().isNotEmpty ? dress.labelAr : dress.labelEn,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(dressLabel),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: WeddingDressHero(dress: dress),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.stone,
                  border: const Border(
                    top: BorderSide(color: AppColors.borderStrong),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fulfillment == WeddingFulfillment.rent) ...[
                          Row(
                            children: [
                              Text(
                                localizedFromLocale(
                                  locale,
                                  AppStrings.weddingRentalDays,
                                  AppStrings.weddingRentalDaysAr,
                                ),
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.fog),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: _rentalDays > 1
                                    ? () => setState(() => _rentalDays -= 1)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: AppColors.gold,
                              ),
                              Text(
                                '$_rentalDays',
                                style: AppTextStyles.labelGold,
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _rentalDays += 1),
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        LolipantsButton(
                          label: localizedFromLocale(
                            locale,
                            fulfillment == WeddingFulfillment.rent
                                ? AppStrings.weddingRentDress
                                : AppStrings.weddingBuyDress,
                            fulfillment == WeddingFulfillment.rent
                                ? AppStrings.weddingRentDressAr
                                : AppStrings.weddingBuyDressAr,
                          ),
                          onPressed: () {
                            context.push(
                              '/order/wedding-summary',
                              extra: WeddingOrderDraft(
                                dressId: dress.id,
                                dressLabel: dress.labelEn,
                                dressImageUrl: dress.imageUrl,
                                category: dress.category,
                                fulfillment: fulfillment,
                                rentalDays: _rentalDays,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
