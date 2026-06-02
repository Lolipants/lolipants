import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/editor_text_fonts.dart';
import 'package:lolipants/features/editor/logic/editor_print_reference.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_preview.dart';
import 'package:lolipants/features/editor/widgets/editor_layer_resize_wrapper.dart';
import 'package:lolipants/features/editor/widgets/editor_print_overlay.dart';

/// Design-catalogue hero: flat-lay PNG with bounded layout (works for casual,
/// traditional, and modern). Casual tees/hoodies/long sleeves also support
/// print, text, and colour overlays.
///
/// Pass [viewportSize] from a parent [LayoutBuilder] at the hero shell so width
/// is never 0 (nested [EditorHeroPreview] can report maxWidth 0).
class DesignFlatlayCompose extends ConsumerWidget {
  const DesignFlatlayCompose({
    required this.designAssetPath,
    required this.state,
    this.viewportSize,
    super.key,
  });

  final String designAssetPath;
  final EditorState state;

  /// When set, paints at this size instead of resolving from child constraints.
  final Size? viewportSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawPath = designAssetPath.trim().isEmpty
        ? kDefaultCatalogDesignPath
        : designAssetPath;
    final lookup = ref.watch(designCatalogLookupProvider);
    final resolved = resolveCatalogDesignImageSource(rawPath, lookup);
    final path = resolved.isNotEmpty ? resolved : rawPath;

    final customizable = isCasualBasicFlatlayPath(rawPath);
    final rawPrint = state.printImagePath?.trim() ?? '';
    final userPrintPath = rawPrint.isNotEmpty &&
            !isEditorReferencePrintImage(
              printPathOrUrl: rawPrint,
              catalogDesignPath: rawPath,
            )
        ? rawPrint
        : '';
    final showOverlays = customizable ||
        state.textLayers.isNotEmpty ||
        userPrintPath.isNotEmpty;

    final hasManipulableOverlay =
        userPrintPath.isNotEmpty || state.textLayers.isNotEmpty;

    final notifier = ref.read(editorProvider.notifier);

    Widget buildAtSize(double width, double height) {
      if (width <= 0 || height <= 0) {
        return const ColoredBox(
          color: kCatalogPreviewBackground,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final canvasSize = Size(width, height);

      final garment = CatalogDesignPreview(
        key: ValueKey<String>(path),
        imageSource: path,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        backgroundColor: kCatalogPreviewBackground,
        tintColor: customizable ? state.primaryColour : null,
        errorWidget: Center(
          child: Text(
            'Design asset missing',
            style: AppTextStyles.bodySmall,
          ),
        ),
      );

      return ColoredBox(
        color: kCatalogPreviewBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              panEnabled: !(showOverlays && hasManipulableOverlay),
              scaleEnabled: !(showOverlays && hasManipulableOverlay),
              minScale: 0.85,
              maxScale: 3,
              child: SizedBox(
                width: width,
                height: height,
                child: garment,
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
                    if (userPrintPath.isNotEmpty)
                      EditorPrintOverlay(
                        path: userPrintPath,
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
                      final selected = layer.id == state.selectedTextLayerId;

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
        ),
      );
    }

    final viewport = viewportSize;
    if (viewport != null &&
        viewport.width > 0 &&
        viewport.height > 0 &&
        viewport.width.isFinite &&
        viewport.height.isFinite) {
      return buildAtSize(viewport.width, viewport.height);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : screen.width;
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : screen.height * 0.45;
        return buildAtSize(width, height);
      },
    );
  }
}
