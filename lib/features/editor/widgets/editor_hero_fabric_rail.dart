import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/fabric_swatch_image.dart';

/// Vertical scrollable fabric swatches on the hero preview (left side).
class EditorHeroFabricRail extends ConsumerWidget {
  const EditorHeroFabricRail({super.key});

  static const double _thumbSize = 44;
  static const double _railWidth = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final fabrics = editor.availableFabrics;

    return Positioned(
      left: 8,
      top: 8,
      bottom: 8,
      width: _railWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.stone.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: fabrics.isEmpty
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: 4,
                ),
                itemCount: fabrics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final fabric = fabrics[index];
                  return _FabricSwatchTile(
                    fabric: fabric,
                    fallbackColour: editor.primaryColour,
                    selected: fabric.id == editor.selectedFabricId,
                    onTap: fabric.isAvailable
                        ? () => notifier.setFabric(fabric.id)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}

class _FabricSwatchTile extends StatelessWidget {
  const _FabricSwatchTile({
    required this.fabric,
    required this.fallbackColour,
    required this.selected,
    required this.onTap,
  });

  final FabricOption fabric;
  final Color fallbackColour;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tooltip = fabric.nameAr.isNotEmpty
        ? '${fabric.name} · ${fabric.nameAr}'
        : fabric.name;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: EditorHeroFabricRail._thumbSize,
            height: EditorHeroFabricRail._thumbSize,
            decoration: BoxDecoration(
              color: AppColors.smoke,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: selected
                    ? AppColors.gold
                    : (enabled
                        ? AppColors.borderSubtle
                        : AppColors.borderDefault),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FabricSwatchImage(
                  fabric: fabric,
                  fallbackColour: fallbackColour,
                ),
                if (selected)
                  const Positioned(
                    top: 2,
                    right: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(1.5),
                        child: Icon(
                          Icons.check,
                          size: 8,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
