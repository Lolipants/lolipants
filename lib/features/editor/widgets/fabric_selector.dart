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

  @override
  Widget build(BuildContext context) {
    const qualities = <String>['standard', 'premium', 'suit_grade'];

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
                  label: Text('${fabric.name} (${fabric.quality})'),
                  selected: selectedFabric == fabric.id,
                  onSelected: (_) => onFabricSelected(fabric.id),
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
