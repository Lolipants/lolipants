import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/utils/fabric_texture_overlay.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_preview.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';
import 'package:lolipants/features/editor/widgets/fabric_textured_garment_layer.dart';

/// Hero: mannequin + configurator layers (unified design); AI look when set.
class EditorHeroPreview extends ConsumerWidget {
  const EditorHeroPreview({
    required this.state,
    required this.activeTab,
    super.key,
  });

  final EditorState state;
  final EditorTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);

    // AI Look tab: refined render only (catalogue flat-lay is Compose / layers).
    if (editor.heroMode == EditorHeroMode.look) {
      return _AiLookBody(state: editor);
    }

    // Catalogue compose hero is rendered in [EditorScreen] (hero shell layout).
    if (editor.heroMode == EditorHeroMode.compose &&
        editor.buildStyleMode == EditorBuildStyleMode.catalog) {
      return const SizedBox.shrink();
    }

    if (kFeatureConfiguratorBuild &&
        editor.heroMode == EditorHeroMode.compose) {
      final catalog = ref.watch(configuratorCatalogProvider);

      ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
          (previous, next) {
        next.whenData((_) {
          ref.read(editorProvider.notifier).ensureDefaultConfiguratorTemplate(
                ref.read(mannequinConfiguratorTemplatesProvider),
              );
        });
      });

      final templates = ref.watch(mannequinConfiguratorTemplatesProvider);

      return catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _BuildComposeBody(state: editor, template: null),
        data: (_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(editorProvider.notifier).ensureDefaultConfiguratorTemplate(
                  templates,
                );
          });

          ConfiguratorTemplate? template;
          final selectedId = editor.configuratorTemplateId.trim();
          if (selectedId.isNotEmpty) {
            for (final t in templates) {
              if (t.id == selectedId) {
                template = t;
                break;
              }
            }
          }
          return _BuildComposeBody(state: editor, template: template);
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _BuildComposeBody extends ConsumerWidget {
  const _BuildComposeBody({
    required this.state,
    required this.template,
  });

  final EditorState state;
  final ConfiguratorTemplate? template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = state.customMannequinImagePath?.trim();
    final bundledPath = builtInMannequinAssetPath(state.mannequinId);
    final mannequinPath =
        (custom != null && custom.isNotEmpty) ? custom : bundledPath;

    final selectedFabric = selectedFabricOption(
      selectedFabricId: state.selectedFabricId,
      availableFabrics: state.availableFabrics,
    );
    final fabricProvider = selectedFabric != null
        ? fabricSwatchImageProvider(selectedFabric)
        : null;

    final layers = template == null
        ? const <ConfiguratorOption>[]
        : collectConfiguratorLayers(
            template: template!,
            selections: state.configuratorSelections,
          );

    if (mannequinPath == null && layers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            AppStrings.editorBuildHeroEmpty,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.fog),
          ),
        ),
      );
    }

    const layerFit = BoxFit.fitHeight;
    const layerAlign = Alignment.bottomCenter;

    return InteractiveViewer(
      minScale: 0.85,
      maxScale: 3,
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.bottomCenter,
          children: [
            if (mannequinPath != null)
              Positioned.fill(
                child: EditorMannequinBody(assetPath: mannequinPath),
              ),
            for (final opt in layers)
              Positioned.fill(
                child: template == null
                    ? ConfiguratorOptionImage(
                        option: opt,
                        tintColor: null,
                        fit: layerFit,
                        alignment: layerAlign,
                      )
                    : FabricTexturedGarmentLayer(
                        option: opt,
                        template: template!,
                        primaryColour: state.primaryColour,
                        accentColour: state.accentColour,
                        fabricProvider: fabricProvider,
                        fit: layerFit,
                        alignment: layerAlign,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AiLookBody extends StatelessWidget {
  const _AiLookBody({required this.state});

  final EditorState state;

  @override
  Widget build(BuildContext context) {
    final url = state.displayRefinedLookUrl;
    if (url != null && url.isNotEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ColoredBox(
            color: Colors.white,
            child: CachedNetworkImage(
              imageUrl: url,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (_, __, ___) => _emptyState(),
            ),
          );
        },
      );
    }
    return _emptyState();
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.checkroom_outlined,
              size: 48,
              color: AppColors.fog,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.editorHeroAiOutputEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.fog),
            ),
          ],
        ),
      ),
    );
  }
}
