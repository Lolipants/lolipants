import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';

/// Shared hero: flat-lay (Designs), mannequin + layers (Build), or AI look.
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
    if (state.heroMode == EditorHeroMode.look) {
      return _AiLookBody(state: state);
    }
    if (activeTab == EditorTab.build) {
      final catalog = ref.watch(configuratorCatalogProvider);
      return catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _BuildComposeBody(state: state, template: null),
        data: (cat) {
          ConfiguratorTemplate? template;
          final selectedId = state.configuratorTemplateId.trim();
          if (selectedId.isNotEmpty) {
            for (final t in cat.templates) {
              if (t.id == selectedId) {
                template = t;
                break;
              }
            }
          }
          return _BuildComposeBody(state: state, template: template);
        },
      );
    }
    return _DesignsFlatLay(state: state);
  }
}

class _DesignsFlatLay extends StatelessWidget {
  const _DesignsFlatLay({required this.state});

  final EditorState state;

  @override
  Widget build(BuildContext context) {
    final path = state.selectedCatalogDesignPath.trim().isEmpty
        ? kDefaultCatalogDesignPath
        : state.selectedCatalogDesignPath;
    return InteractiveViewer(
      minScale: 0.85,
      maxScale: 3,
      child: Center(
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              'Design asset missing',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
      ),
    );
  }
}

class _BuildComposeBody extends StatelessWidget {
  const _BuildComposeBody({
    required this.state,
    required this.template,
  });

  final EditorState state;
  final ConfiguratorTemplate? template;

  @override
  Widget build(BuildContext context) {
    final custom = state.customMannequinImagePath?.trim();
    final bundledPath = builtInMannequinAssetPath(state.mannequinId);
    final mannequinPath = (custom != null && custom.isNotEmpty)
        ? custom
        : bundledPath;

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
                child: ConfiguratorOptionImage(
                  option: opt,
                  fit: layerFit,
                  alignment: layerAlign,
                  primaryTint: state.primaryColour,
                  accentTint: state.accentColour,
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
    final url = state.refinedLookUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
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
