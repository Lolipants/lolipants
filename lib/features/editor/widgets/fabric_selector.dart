import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';

/// Horizontal fabric picker + quality-tier chip row shown as the Fabric tab
/// content of the editor bottom panel. Pure presentation; the editor provider
/// owns the selection state.
class FabricSelector extends StatelessWidget {
  /// Creates a fabric selector.
  const FabricSelector({
    required this.selectedFabric,
    required this.availableFabrics,
    required this.quality,
    required this.onFabricSelected,
    required this.onQualitySelected,
    this.compact = false,
    super.key,
  });

  /// Currently selected fabric id.
  final String selectedFabric;

  /// Fabrics available for the current garment type.
  final List<FabricOption> availableFabrics;

  /// Currently selected fabric quality (`standard`/`premium`/`suit_grade`).
  final String quality;

  /// Invoked when the user picks a fabric chip.
  final ValueChanged<String> onFabricSelected;

  /// Invoked when the user picks a quality chip.
  final ValueChanged<String> onQualitySelected;

  /// Compact horizontal layout for the hero preview overlay.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const qualities = <String>['standard', 'premium', 'suit_grade'];

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final fabric in availableFabrics)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          fabric.name,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: selectedFabric == fabric.id,
                        onSelected: fabric.isAvailable
                            ? (_) => onFabricSelected(fabric.id)
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final q in qualities)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          q.replaceAll('_', '-'),
                          style: const TextStyle(fontSize: 10),
                        ),
                        selected: quality == q,
                        onSelected: (_) => onQualitySelected(q),
                        selectedColor: AppColors.gold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final fabric in availableFabrics)
                ChoiceChip(
                  label: Text(
                    fabric.nameAr.isNotEmpty
                        ? '${fabric.name} · ${fabric.nameAr}'
                        : fabric.name,
                  ),
                  selected: selectedFabric == fabric.id,
                  onSelected: fabric.isAvailable
                      ? (_) => onFabricSelected(fabric.id)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final q in qualities)
                ChoiceChip(
                  label: Text(q.replaceAll('_', '-')),
                  selected: quality == q,
                  onSelected: (_) => onQualitySelected(q),
                  selectedColor: AppColors.gold,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
