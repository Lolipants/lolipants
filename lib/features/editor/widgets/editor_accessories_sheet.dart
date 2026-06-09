import 'dart:ui' show Locale;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/l10n/localized_label.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/accessories/providers/accessories_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Multi-select sheet for garment order accessory add-ons.
class EditorAccessoriesSheet extends ConsumerStatefulWidget {
  const EditorAccessoriesSheet({super.key});

  @override
  ConsumerState<EditorAccessoriesSheet> createState() =>
      _EditorAccessoriesSheetState();
}

class _EditorAccessoriesSheetState extends ConsumerState<EditorAccessoriesSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(editorProvider).selectedAccessoryIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);

    if (!kFeatureAccessories) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          localizedFromLocale(
            locale,
            AppStrings.editorAccessoriesUnavailable,
            AppStrings.editorAccessoriesUnavailableAr,
          ),
        ),
      );
    }

    final addonsAsync = ref.watch(addonAccessoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizedFromLocale(
              locale,
              AppStrings.editorAddAccessories,
              AppStrings.editorAddAccessoriesAr,
            ),
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localizedFromLocale(
              locale,
              AppStrings.editorAccessoriesSubtitle,
              AppStrings.editorAccessoriesSubtitleAr,
            ),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
          ),
          const SizedBox(height: AppSpacing.md),
          addonsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              localizedFromLocale(
                locale,
                AppStrings.editorAccessoriesLoadError,
                AppStrings.editorAccessoriesLoadErrorAr,
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  localizedFromLocale(
                    locale,
                    AppStrings.editorAccessoriesEmpty,
                    AppStrings.editorAccessoriesEmptyAr,
                  ),
                );
              }
              return SizedBox(
                height: 280,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = _selected.contains(item.id);
                    return _AccessoryRow(
                      accessory: item,
                      locale: locale,
                      selected: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              final ids = _selected.toList(growable: false);
              final labels = addonsAsync.valueOrNull
                      ?.where((a) => ids.contains(a.id))
                      .map(
                        (a) => localizedLabel(
                          locale,
                          en: a.labelEn,
                          ar: a.labelAr.trim().isNotEmpty
                              ? a.labelAr
                              : a.labelEn,
                        ),
                      )
                      .toList(growable: false) ??
                  const <String>[];
              ref.read(editorProvider.notifier).setSelectedAccessories(
                    ids: ids,
                    summary: labels.join(', '),
                  );
              Navigator.of(context).pop();
            },
            child: Text(
              localizedFromLocale(
                locale,
                AppStrings.editorDone,
                AppStrings.editorDoneAr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryRow extends StatelessWidget {
  const _AccessoryRow({
    required this.accessory,
    required this.locale,
    required this.selected,
    required this.onChanged,
  });

  final Accessory accessory;
  final Locale locale;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: selected,
      onChanged: (v) => onChanged(v ?? false),
      secondary: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: accessory.imageUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        localizedLabel(
          locale,
          en: accessory.labelEn,
          ar: accessory.labelAr.trim().isNotEmpty
              ? accessory.labelAr
              : accessory.labelEn,
        ),
      ),
      subtitle: Text('${accessory.salePrice.round()} QAR'),
    );
  }
}

void showEditorAccessoriesSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const EditorAccessoriesSheet(),
  );
}
