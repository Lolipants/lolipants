import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/l10n/localized_label.dart';
import 'package:lolipants/features/editor/widgets/editor_asset_thumb_card.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';
import 'package:lolipants/features/wedding/models/wedding_flow_args.dart';
import 'package:lolipants/features/wedding/providers/wedding_providers.dart';
import 'package:lolipants/features/wedding/widgets/wedding_filter_chip.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Standalone wedding dress catalogue (fulfillment chosen earlier).
class WeddingDressBrowseScreen extends ConsumerStatefulWidget {
  const WeddingDressBrowseScreen({this.flowArgs, super.key});

  final WeddingFlowArgs? flowArgs;

  @override
  ConsumerState<WeddingDressBrowseScreen> createState() =>
      _WeddingDressBrowseScreenState();
}

class _WeddingDressBrowseScreenState
    extends ConsumerState<WeddingDressBrowseScreen> {
  WeddingCategoryFilter _filter = WeddingCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.flowArgs?.fulfillment == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replace('/wedding/fulfillment');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kFeatureWeddingFlow) {
      return const Scaffold(
        body: Center(child: Text('Wedding flow is not available')),
      );
    }

    final fulfillment = widget.flowArgs?.fulfillment;
    if (fulfillment == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final locale = ref.watch(settingsLocaleProvider);
    final asyncDresses = ref.watch(weddingDressesProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTabWedding,
            AppStrings.editorTabWeddingAr,
          ),
        ),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Column(
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
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      WeddingFilterChip(
                        label: localizedFromLocale(
                          locale,
                          AppStrings.weddingFilterAll,
                          AppStrings.weddingFilterAllAr,
                        ),
                        selected: _filter == WeddingCategoryFilter.all,
                        onTap: () => setState(
                          () => _filter = WeddingCategoryFilter.all,
                        ),
                      ),
                      const SizedBox(width: 6),
                      WeddingFilterChip(
                        label: localizedFromLocale(
                          locale,
                          AppStrings.weddingFilterBridal,
                          AppStrings.weddingFilterBridalAr,
                        ),
                        selected:
                            _filter == WeddingCategoryFilter.weddingDress,
                        onTap: () => setState(
                          () => _filter = WeddingCategoryFilter.weddingDress,
                        ),
                      ),
                      const SizedBox(width: 6),
                      WeddingFilterChip(
                        label: localizedFromLocale(
                          locale,
                          AppStrings.weddingFilterBridesmaids,
                          AppStrings.weddingFilterBridesmaidsAr,
                        ),
                        selected: _filter == WeddingCategoryFilter.bridesmaid,
                        onTap: () => setState(
                          () => _filter = WeddingCategoryFilter.bridesmaid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: asyncDresses.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                    return GridView.builder(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: dresses.length,
                      itemBuilder: (context, index) {
                        final dress = dresses[index];
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
                          selected: false,
                          onTap: () => context.push(
                            '/wedding/dress',
                            extra: WeddingDressDetailArgs(
                              dress: dress,
                              fulfillment: fulfillment,
                              flowArgs: widget.flowArgs,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
