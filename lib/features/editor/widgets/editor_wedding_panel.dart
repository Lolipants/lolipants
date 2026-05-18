import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
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
    super.key,
  });

  final EditorState state;
  final ValueChanged<String> onDressSelected;
  final ValueChanged<WeddingCategoryFilter> onCategoryChanged;
  final ValueChanged<WeddingFulfillment> onFulfillmentChanged;
  final ValueChanged<int> onRentalDaysChanged;
  final double? height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDresses =
        ref.watch(weddingDressesProvider(state.weddingCategoryFilter));
    final panelHeight = height ??
        (MediaQuery.sizeOf(context).height * 0.40).clamp(280.0, 380.0);

    return SizedBox(
      height: panelHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          border: const Border(top: BorderSide(color: AppColors.borderStrong)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: AppStrings.weddingFilterAll,
                      selected:
                          state.weddingCategoryFilter == WeddingCategoryFilter.all,
                      onTap: () =>
                          onCategoryChanged(WeddingCategoryFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: AppStrings.weddingFilterBridal,
                      selected: state.weddingCategoryFilter ==
                          WeddingCategoryFilter.weddingDress,
                      onTap: () => onCategoryChanged(
                        WeddingCategoryFilter.weddingDress,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: AppStrings.weddingFilterBridesmaids,
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
                      label: AppStrings.weddingRent,
                      selected: state.weddingFulfillment == WeddingFulfillment.rent,
                      onTap: () => onFulfillmentChanged(WeddingFulfillment.rent),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _FulfillmentToggle(
                      label: AppStrings.weddingBuy,
                      selected: state.weddingFulfillment == WeddingFulfillment.buy,
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
                      AppStrings.weddingRentalDays,
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
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(
                    AppStrings.weddingCatalogError,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                data: (dresses) {
                  if (dresses.isEmpty) {
                    return Center(
                      child: Text(
                        AppStrings.weddingCatalogEmpty,
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
                        label: dress.labelEn,
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
        ),
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
