import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/design_flatlay_compose.dart';

/// Design-catalogue hero for Compose / layers (bounded by the hero shell).
class EditorCatalogComposeHero extends ConsumerWidget {
  const EditorCatalogComposeHero({super.key});

  static double _finiteDimension(double constraint, double fallback) {
    if (constraint.isFinite && constraint > 0) return constraint;
    return fallback;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final path = editor.selectedCatalogDesignPath.trim();
    final assetPath = path.isEmpty ? kDefaultCatalogDesignPath : path;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final w = _finiteDimension(constraints.maxWidth, screen.width);
        final h = _finiteDimension(
          constraints.maxHeight,
          screen.height * 0.45,
        );

        return DesignFlatlayCompose(
          designAssetPath: assetPath,
          state: editor,
          viewportSize: Size(w, h),
        );
      },
    );
  }
}
