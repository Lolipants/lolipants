import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/accessories/providers/accessories_providers.dart';
import 'package:lolipants/features/accessories/widgets/accessory_card.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

/// Accessories category hub: filters + CMS-backed product grid.
class AccessoriesBrowseSection extends ConsumerStatefulWidget {
  const AccessoriesBrowseSection({required this.onDesignTshirt, super.key});

  final VoidCallback onDesignTshirt;

  @override
  ConsumerState<AccessoriesBrowseSection> createState() =>
      _AccessoriesBrowseSectionState();
}

class _AccessoriesBrowseSectionState extends ConsumerState<AccessoriesBrowseSection> {
  AccessoryCategoryFilter _filter = AccessoryCategoryFilter.all;

  @override
  Widget build(BuildContext context) {
    if (!kFeatureAccessories) {
      return _LegacyPlaceholder(onDesignTshirt: widget.onDesignTshirt);
    }

    final accessoriesAsync = ref.watch(accessoriesListProvider(_filter));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          AppStrings.homeAccessoriesSubtitle,
          style: AppTextStyles.bodyMedium,
        ),
        if (kFeatureCasual) ...[
          const SizedBox(height: AppSpacing.lg),
          LolipantsButton(
            label: localizedFromContext(
              context,
              AppStrings.accessoriesTshirtCta,
              AppStrings.accessoriesTshirtCtaAr,
            ),
            onPressed: widget.onDesignTshirt,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in AccessoryCategoryFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(accessoryCategoryLabel(f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        accessoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Could not load accessories.'),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No accessories in this category yet.');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AccessoryCard(
                  accessory: item,
                  onTap: () {
                    context.push(
                      '/browse/accessory/${item.id}',
                      extra: item,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _LegacyPlaceholder extends StatelessWidget {
  const _LegacyPlaceholder({required this.onDesignTshirt});

  final VoidCallback onDesignTshirt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(AppStrings.homeAccessoriesSubtitle, style: AppTextStyles.bodyMedium),
        if (kFeatureCasual) ...[
          const SizedBox(height: AppSpacing.lg),
          LolipantsButton(
            label: localizedFromContext(
              context,
              AppStrings.accessoriesTshirtCta,
              AppStrings.accessoriesTshirtCtaAr,
            ),
            onPressed: onDesignTshirt,
          ),
        ],
      ],
    );
  }
}
