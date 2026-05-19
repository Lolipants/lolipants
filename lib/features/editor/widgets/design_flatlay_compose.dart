import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/editor_text_fonts.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_layer_resize_wrapper.dart';
import 'package:lolipants/features/editor/widgets/editor_print_overlay.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';

/// Catalogue flat-lay with optional print and text overlays (casual customization).
class DesignFlatlayCompose extends ConsumerWidget {
  const DesignFlatlayCompose({
    required this.designAssetPath,
    required this.state,
    super.key,
  });

  final String designAssetPath;
  final EditorState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = designAssetPath.trim().isEmpty
        ? kDefaultCatalogDesignPath
        : designAssetPath;
    final showOverlays = isCasualEditorContext(
          selectedCatalogDesignPath: path,
          catalogFilter: state.catalogFilter,
        ) ||
        state.textLayers.isNotEmpty ||
        (state.printImagePath?.trim().isNotEmpty ?? false);

    final hasManipulableOverlay = (state.printImagePath?.trim().isNotEmpty ??
            false) ||
        state.textLayers.isNotEmpty;

    final notifier = ref.read(editorProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final canvasSize = Size(width, height);

        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: !(showOverlays && hasManipulableOverlay),
              scaleEnabled: !(showOverlays && hasManipulableOverlay),
              minScale: 0.85,
              maxScale: 3,
              child: Center(
                child: CatalogImage(
                  path: path,
                  key: ValueKey<String>(path),
                  fit: BoxFit.contain,
                  errorWidget: Center(
                    child: Text(
                      'Design asset missing',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            if (showOverlays)
              Positioned.fill(
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: notifier.clearOverlaySelection,
                      ),
                    ),
                    if (state.printImagePath != null &&
                        state.printImagePath!.trim().isNotEmpty)
                      EditorPrintOverlay(
                        path: state.printImagePath!,
                        placement: state.printPlacement,
                        scalePercent: state.printScale,
                        offsetX: state.printOffsetX,
                        offsetY: state.printOffsetY,
                        selected: state.isPrintOverlaySelected,
                        chestTopPadding: height * 0.22,
                        defaultTopPadding: height * 0.28,
                        onTap: notifier.selectPrintOverlay,
                        onDragUpdate: notifier.nudgePrintOffset,
                        onResize: notifier.adjustPrintScaleByHandle,
                      ),
                    ...state.textLayers.map((layer) {
                      final left =
                          (layer.placement.dx.clamp(0.1, 0.9) * width) - 55;
                      final top =
                          (layer.placement.dy.clamp(0.2, 0.95) * height) - 14;
                      final selected =
                          layer.id == state.selectedTextLayerId;

                      return Positioned(
                        left: left,
                        top: top,
                        child: EditorLayerResizeWrapper(
                          selected: selected,
                          onTap: () => notifier.selectTextLayer(layer.id),
                          onMove: selected
                              ? (delta) {
                                  notifier.nudgeTextLayerPlacement(
                                    layer.id,
                                    delta,
                                    canvasSize,
                                  );
                                }
                              : null,
                          onResize: selected
                              ? (handle, delta) {
                                  notifier.adjustTextLayerSizeByHandle(
                                    layer.id,
                                    handle,
                                    delta,
                                  );
                                }
                              : null,
                          child: Transform.rotate(
                            angle: layer.rotation,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                layer.text,
                                style: editorLayerTextStyle(
                                  fontFamily: layer.fontFamily,
                                  fontSize: layer.fontSize,
                                  color: layer.colour,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0.8, 0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
