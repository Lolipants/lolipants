import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';
import 'package:lolipants/features/accessories/providers/accessories_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';

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
    if (!kFeatureAccessories) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text('Accessories are not available in this build.'),
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
          Text('Add accessories', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Optional items included with your garment order.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
          ),
          const SizedBox(height: AppSpacing.md),
          addonsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load accessories.'),
            data: (items) {
              if (items.isEmpty) {
                return const Text('No add-on accessories available.');
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
                      .map((a) => a.labelEn)
                      .toList(growable: false) ??
                  const <String>[];
              ref.read(editorProvider.notifier).setSelectedAccessories(
                    ids: ids,
                    summary: labels.join(', '),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _AccessoryRow extends StatelessWidget {
  const _AccessoryRow({
    required this.accessory,
    required this.selected,
    required this.onChanged,
  });

  final Accessory accessory;
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
      title: Text(accessory.labelEn),
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
