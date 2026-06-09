import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/l10n/localized_label.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/providers/wedding_providers.dart';

/// Bottom panel for the Wedding tab: filters, dress picker, rent/buy, rental days.
class EditorWeddingPanel extends ConsumerWidget {
  const EditorWeddingPanel({
    required this.state,
    required this.onDressSelected,
    required this.onCategoryChanged,
    required this.onFulfillmentChanged,
    required this.onRentalDaysChanged,
    this.height,
    this.embedded = false,
    super.key,
  });

  final EditorState state;
  final ValueChanged<String> onDressSelected;
  final ValueChanged<WeddingCategoryFilter> onCategoryChanged;
  final ValueChanged<WeddingFulfillment> onFulfillmentChanged;
  final ValueChanged<int> onRentalDaysChanged;
  final double? height;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final asyncDresses =
        ref.watch(weddingDressesProvider(state.weddingCategoryFilter));
    final panelHeight = height ??
        (MediaQuery.sizeOf(context).height * 0.40).clamp(280.0, 380.0);

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            embedded ? AppSpacing.xs : AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.weddingFilterAll,
                    AppStrings.weddingFilterAllAr,
                  ),
                  selected:
                      state.weddingCategoryFilter == WeddingCategoryFilter.all,
                  onTap: () => onCategoryChanged(WeddingCategoryFilter.all),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.weddingFilterBridal,
                    AppStrings.weddingFilterBridalAr,
                  ),
                  selected: state.weddingCategoryFilter ==
                      WeddingCategoryFilter.weddingDress,
                  onTap: () =>
                      onCategoryChanged(WeddingCategoryFilter.weddingDress),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.weddingFilterBridesmaids,
                    AppStrings.weddingFilterBridesmaidsAr,
                  ),
                  selected: state.weddingCategoryFilter ==
                      WeddingCategoryFilter.bridesmaid,
                  onTap: () =>
                      onCategoryChanged(WeddingCategoryFilter.bridesmaid),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: _FulfillmentToggle(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.weddingRent,
                    AppStrings.weddingRentAr,
                  ),
                  selected:
                      state.weddingFulfillment == WeddingFulfillment.rent,
                  onTap: () => onFulfillmentChanged(WeddingFulfillment.rent),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _FulfillmentToggle(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.weddingBuy,
                    AppStrings.weddingBuyAr,
                  ),
                  selected:
                      state.weddingFulfillment == WeddingFulfillment.buy,
                  onTap: () => onFulfillmentChanged(WeddingFulfillment.buy),
                ),
              ),
            ],
          ),
        ),
        if (state.weddingFulfillment == WeddingFulfillment.rent)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              0,
            ),
            child: Row(
              children: [
                Text(
                  localizedFromLocale(
                    locale,
                    AppStrings.weddingRentalDays,
                    AppStrings.weddingRentalDaysAr,
                  ),
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: state.rentalDays > 1
                      ? () => onRentalDaysChanged(state.rentalDays - 1)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.gold,
                ),
                Text(
                  '${state.rentalDays}',
                  style: AppTextStyles.labelGold,
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRentalDaysChanged(state.rentalDays + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: asyncDresses.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                localizedFromLocale(
                  locale,
                  AppStrings.weddingCatalogError,
                  AppStrings.weddingCatalogErrorAr,
                ),
                style: AppTextStyles.bodySmall,
              ),
            ),
            data: (dresses) {
              if (dresses.isEmpty) {
                return Center(
                  child: Text(
                    localizedFromLocale(
                      locale,
                      AppStrings.weddingCatalogEmpty,
                      AppStrings.weddingCatalogEmptyAr,
                    ),
                    style: AppTextStyles.bodySmall,
                  ),
                );
              }
              final selectedId = state.selectedWeddingDressId;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (selectedId == null && dresses.isNotEmpty) {
                  onDressSelected(dresses.first.id);
                }
              });
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                itemCount: dresses.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final dress = dresses[index];
                  final selected = dress.id == selectedId;
                  return EditorAssetThumbCard(
                    label: localizedLabel(
                      locale,
                      en: dress.labelEn,
                      ar: dress.labelAr.trim().isNotEmpty
                          ? dress.labelAr
                          : dress.labelEn,
                    ),
                    image: CachedNetworkImage(
                      imageUrl: dress.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    selected: selected,
                    onTap: () => onDressSelected(dress.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (embedded) return body;

    return SizedBox(
      height: panelHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: body,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.stone,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelGold.copyWith(
              color: selected ? AppColors.gold : AppColors.fog,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _FulfillmentToggle extends StatelessWidget {
  const _FulfillmentToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderDefault,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelGold.copyWith(
              color: selected ? AppColors.gold : AppColors.fog,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
