import 'dart:io';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lolipants/core/ai/ai_data_sharing_consent.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/screens/create_post_screen.dart';
import 'package:lolipants/features/community/utils/publish_showcase_feedback.dart';
import 'package:lolipants/features/community/widgets/publish_showcase_dialog.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/models/catalog_design_pick.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/editor_design_restore.dart';
import 'package:lolipants/features/editor/logic/catalog_compose_hero.dart';
import 'package:lolipants/features/editor/logic/pick_custom_mannequin_photo.dart';
import 'package:lolipants/features/editor/widgets/catalog_design_preview.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/editor/widgets/editor_ai_refine_cta.dart';
import 'package:lolipants/features/editor/widgets/editor_hero_fabric_rail.dart';
import 'package:lolipants/features/editor/widgets/editor_compose_tool_rail.dart';
import 'package:lolipants/features/editor/widgets/editor_bottom_panel.dart';
import 'package:lolipants/features/editor/widgets/editor_design_summary_bar.dart';
import 'package:lolipants/features/editor/providers/configurator_providers.dart';
import 'package:lolipants/features/editor/widgets/editor_catalog_compose_hero.dart';
import 'package:lolipants/features/editor/widgets/editor_hero_preview.dart';
import 'package:lolipants/features/editor/widgets/editor_style_picker_sheet.dart';
import 'package:lolipants/features/editor/widgets/image_print_panel.dart';
import 'package:lolipants/features/editor/widgets/refine_body_reference_sheet.dart';
import 'package:lolipants/features/editor/widgets/text_tool_panel.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

/// Phase 3A editor shell screen.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({
    super.key,
    this.initialMannequinId,
    this.preset,
    this.design,
    this.bootstrap,
  });

  final String? initialMannequinId;
  final EditorPresetArgs? preset;
  final GarmentDesign? design;
  final EditorBootstrapArgs? bootstrap;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _seededSession = false;
  bool _sharing = false;
  bool _pendingAiHomeDraft = false;
  bool _aiHomeDraftRunning = false;
  final GlobalKey _heroCaptureKey = GlobalKey();
  late final EditorNotifier _editorNotifier;

  @override
  void initState() {
    super.initState();
    _editorNotifier = ref.read(editorProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedEditorSession());
  }

  @override
  void didUpdateWidget(covariant EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDesignId = oldWidget.design?.id;
    final newDesignId = widget.design?.id;
    if (oldDesignId != newDesignId ||
        oldWidget.preset != widget.preset ||
        oldWidget.bootstrap?.mannequinId != widget.bootstrap?.mannequinId ||
        oldWidget.bootstrap?.preset != widget.bootstrap?.preset) {
      _seededSession = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedEditorSession());
    }
  }

  void _seedEditorSession() {
    if (!mounted || _seededSession) return;
    final notifier = _editorNotifier;
    if (widget.design != null) {
      notifier.loadDesign(widget.design!);
      if (isAiHomeDraftFromRenderMetadata(widget.design!.renderMetadata)) {
        _pendingAiHomeDraft = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _runAiHomeDraftIfReady();
        });
      }
    } else {
      final initialMannequin =
          widget.bootstrap?.mannequinId ?? widget.initialMannequinId;
      final preset = widget.bootstrap?.preset ?? widget.preset;
      final catalogPath = preset?.catalogDesignPath;
      final fromBrowse = widget.bootstrap?.source == 'browse_design' &&
          preset != null &&
          catalogPath != null &&
          isEditorCatalogDesignRef(catalogPath);
      if (fromBrowse) {
        notifier.bootstrapBrowseDesign(
          preset: preset,
          mannequinId: initialMannequin,
          customMannequinImagePath: widget.bootstrap?.customMannequinImagePath,
        );
      } else {
        final homeFlow = widget.bootstrap?.homeFlow;
        final fromHomeFlow = widget.bootstrap?.source == 'home_flow' &&
            homeFlow != null &&
            homeFlow.isComplete &&
            homeFlow.serviceType != null &&
            homeFlow.style != null;
        if (fromHomeFlow) {
          notifier.bootstrapHomeFlow(
            serviceType: homeFlow.serviceType!,
            styleLane: homeFlow.style!,
            mannequinId: initialMannequin,
            customMannequinImagePath: widget.bootstrap?.customMannequinImagePath,
          );
        } else {
          notifier.beginNewDesign(
            mannequinId: initialMannequin,
            customMannequinImagePath: widget.bootstrap?.customMannequinImagePath,
          );
          if (preset != null) {
            notifier.loadPreset(preset);
          }
        }
      }
    }
    _seededSession = true;
    notifier.loadFabrics();
    final tabName = widget.bootstrap?.initialTab?.trim().toLowerCase();
    if (tabName == 'build' ||
        tabName == 'designs' ||
        tabName == 'design') {
      if (kFeatureConfiguratorBuild) {
        notifier.setInitialTab(EditorTab.build);
      }
    }
    if (mounted) {
      notifier.syncBuildLaneForMannequin(
        ref.read(mannequinConfiguratorTemplatesProvider),
      );
    }
  }

  /// After home AI "Apply", generates a look from the text prompt + mannequin only.
  Future<void> _runAiHomeDraftIfReady() async {
    if (!_pendingAiHomeDraft || _aiHomeDraftRunning || !mounted) return;

    _aiHomeDraftRunning = true;
    _pendingAiHomeDraft = false;

    final notifier = _editorNotifier;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final allowed = await AiDataSharingConsent.ensure(context, ref);
    if (!allowed || !mounted) {
      _aiHomeDraftRunning = false;
      return;
    }

    final result = await notifier.generateRefinedLook(
      promptOnlyRender: true,
    );
    if (!mounted) return;
    _aiHomeDraftRunning = false;
    if (!result.success &&
        result.message != null &&
        result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  @override
  void dispose() {
    // Riverpod forbids mutating providers during dispose; defer until after
    // this frame's build/unmount cycle completes.
    final notifier = _editorNotifier;
    Future.microtask(notifier.resetConfigurator);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ConfiguratorCatalog>>(configuratorCatalogProvider,
        (previous, next) {
      next.whenData((_) {
        if (_pendingAiHomeDraft && !_aiHomeDraftRunning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _runAiHomeDraftIfReady();
          });
        }
      });
    });

    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final mannequinTemplates = ref.watch(mannequinConfiguratorTemplatesProvider);
    ref.listen<List<ConfiguratorTemplate>>(
      mannequinConfiguratorTemplatesProvider,
      (previous, next) {
        if (!_seededSession) return;
        notifier.syncBuildLaneForMannequin(next);
      },
    );
    final hasConfigurator = mannequinTemplates.isNotEmpty;
    final quotaAsync = ref.watch(aiRenderQuotaProvider);
    final canGenerateLook =
        !editor.lookGenerating && (quotaAsync.valueOrNull?.canRender ?? true);
    final showCatalogComposeHero = showsCatalogComposeHero(editor);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit(context);
      },
      child: Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shellHeight = constraints.maxHeight;
                final bottomPanelHeight =
                    (shellHeight * 0.36).clamp(180.0, 280.0);

                return Column(
                  children: [
                    _EditorTopBar(
                      onBack: () => _confirmExit(context),
                      onSave: () => _saveDesign(context),
                      onOrder: () => _orderNow(context),
                      onShare: () => _showShareOptions(context),
                      onSizing: () => context.push('/sizing'),
                      saving: editor.isSaving,
                      heroMode: editor.heroMode,
                      onHeroModeChanged: notifier.setHeroMode,
                      aiLookEnabled: hasConfigurator,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.sm,
                                4,
                                AppSpacing.sm,
                                4,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: showCatalogComposeHero
                                      ? kCatalogPreviewBackground
                                      : AppColors.smoke
                                          .withValues(alpha: 0.45),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(
                                    color: AppColors.borderSubtle
                                        .withValues(alpha: 0.65),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 28,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          key: _heroCaptureKey,
                                          child: showCatalogComposeHero
                                              ? const EditorCatalogComposeHero()
                                              : DecoratedBox(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                  ),
                                                  child: SizedBox.expand(
                                                    child: EditorHeroPreview(
                                                      state: editor,
                                                      activeTab:
                                                          editor.activeTab,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (editor.lookGenerating)
                                        Positioned.fill(
                                          child: ColoredBox(
                                            color: Colors.black
                                                .withValues(alpha: 0.25),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ),
                                      if (editor.heroMode ==
                                              EditorHeroMode.compose &&
                                          editor.buildStyleMode !=
                                              EditorBuildStyleMode.catalog)
                                        const EditorHeroFabricRail(),
                                      if (editor.heroMode ==
                                          EditorHeroMode.compose)
                                        EditorComposeToolRail(
                                          editor: editor,
                                          onPalette: () =>
                                              _onHeroPalettePressed(context),
                                          onAddText: () =>
                                              _showTextToolSheet(context),
                                          onAddImage: () =>
                                              _showImagePrintSheet(context),
                                        ),
                                      EditorRefineFab(
                                          onPressed: canGenerateLook
                                              ? () => _generateLook(
                                                    context,
                                                    promptBodyReference: true,
                                                  )
                                              : null,
                                        ),
                                      if (editor.heroMode ==
                                              EditorHeroMode.look &&
                                          editor.displayRefinedLookUrl != null)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton.filledTonal(
                                            tooltip:
                                                AppStrings.editorGenerateLook,
                                            onPressed: canGenerateLook
                                                ? () => _generateLook(context)
                                                : null,
                                            icon: const Icon(Icons.refresh),
                                          ),
                                        ),
                                      if (editor.heroMode ==
                                              EditorHeroMode.look &&
                                          editor.displayRefinedLookUrl != null)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: IgnorePointer(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    AppColors.ink.withValues(
                                                      alpha: 0.88,
                                                    ),
                                                    AppColors.ink.withValues(
                                                      alpha: 0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                  AppSpacing.md,
                                                  AppSpacing.lg,
                                                  AppSpacing.md,
                                                  AppSpacing.sm,
                                                ),
                                                child: Text(
                                                  AppStrings
                                                      .editorLookDisclaimer,
                                                  style: AppTextStyles.bodySmall
                                                      .copyWith(
                                                    color: AppColors.sand
                                                        .withValues(
                                                            alpha: 0.92),
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const EditorDesignSummaryBar(),
                        ],
                      ),
                    ),
                    if (kFeatureConfiguratorBuild)
                      EditorBottomPanel(
                        height: bottomPanelHeight,
                        onGenerateAi: () => _generateLook(context),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _onHeroPalettePressed(BuildContext context) {
    final editor = ref.read(editorProvider);
    if (editor.buildStyleMode == EditorBuildStyleMode.catalog &&
        !isCasualBasicFlatlayPath(editor.selectedCatalogDesignPath)) {
      return;
    }
    _openStylePicker(context);
  }

  Future<void> _openStylePicker(BuildContext context) async {
    final notifier = ref.read(editorProvider.notifier);
    final editor = ref.read(editorProvider);
    if (editor.availableFabrics.isEmpty) {
      await notifier.loadFabrics();
    }
    if (!context.mounted) return;
    showEditorStylePickerSheet(context);
  }

  void _showTextToolSheet(BuildContext context) {
    final editor = ref.read(editorProvider);
    if (editor.buildStyleMode == EditorBuildStyleMode.catalog &&
        !isCasualBasicFlatlayPath(editor.selectedCatalogDesignPath)) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.stone,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final ed = ref.watch(editorProvider);
                final notifier = ref.read(editorProvider.notifier);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.editorTabText,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    Expanded(
                      child: TextToolPanel(
                        layers: ed.textLayers,
                        selectedLayer: notifier.selectedTextLayer,
                        onAddLayer: notifier.addTextLayer,
                        onSelectLayer: notifier.selectTextLayer,
                        onUpdateSelected: ({
                          String? fontFamily,
                          double? fontSize,
                          Color? colour,
                          double? rotation,
                        }) =>
                            notifier.updateSelectedText(
                          fontFamily: fontFamily,
                          fontSize: fontSize,
                          colour: colour,
                          rotation: rotation,
                        ),
                        onRemoveSelected: notifier.removeSelectedText,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showImagePrintSheet(BuildContext context) {
    final editor = ref.read(editorProvider);
    if (editor.buildStyleMode == EditorBuildStyleMode.catalog &&
        !isCasualBasicFlatlayPath(editor.selectedCatalogDesignPath)) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.stone,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                final ed = ref.watch(editorProvider);
                final notifier = ref.read(editorProvider.notifier);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.editorAddImage,
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: ImagePrintPanel(
                          imagePath: ed.printImagePath,
                          sketchPath: ed.sketchImagePath,
                          placement: ed.printPlacement,
                          offsetX: ed.printOffsetX,
                          offsetY: ed.printOffsetY,
                          scale: ed.printScale,
                          onImageSelected: notifier.setPrintImagePath,
                          onSketchSelected: notifier.setSketchImagePath,
                          onPlacementChanged: notifier.setPrintPlacement,
                          onOffsetXChanged: notifier.setPrintOffsetX,
                          onOffsetYChanged: notifier.setPrintOffsetY,
                          onScaleChanged: notifier.setPrintScale,
                          minScale: 20,
                          maxScale: 120,
                          onApply: () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateLook(
    BuildContext context, {
    bool promptBodyReference = false,
  }) async {
    final notifier = ref.read(editorProvider.notifier);

    if (promptBodyReference) {
      final choice = await showRefineBodyReferenceSheet(context, ref);
      if (choice == null || !context.mounted) return;

      switch (choice) {
        case RefineBodyReference.mannequin:
          notifier.setCustomMannequinImagePath(null);
          await WidgetsBinding.instance.endOfFrame;
        case RefineBodyReference.customPhoto:
          final path = await pickCustomMannequinPhoto(context, ref);
          if (path == null || !context.mounted) return;
          notifier.setCustomMannequinImagePath(path);
          await WidgetsBinding.instance.endOfFrame;
      }
    }

    final allowed = await AiDataSharingConsent.ensure(context, ref);
    if (!allowed || !context.mounted) return;

    final editor = ref.read(editorProvider);
    if (editor.heroMode != EditorHeroMode.compose) {
      notifier.setHeroMode(EditorHeroMode.compose);
      await WidgetsBinding.instance.endOfFrame;
    }
    final isCatalog = editor.buildStyleMode == EditorBuildStyleMode.catalog;
    final composeBytes =
        isCatalog ? null : await _captureHeroPng();
    final result = await notifier.generateRefinedLook(
      composePreviewBytes: composeBytes,
    );
    if (!context.mounted) return;
    if (result.success) {
      final locale = ref.read(settingsLocaleProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizedFromLocale(
              locale,
              AppStrings.editorLookGeneratedSnack,
              AppStrings.editorLookGeneratedSnackAr,
            ),
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
        ),
      );
    } else if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  Future<void> _confirmExit(BuildContext context) async {
    final editor = ref.read(editorProvider);
    if (!editor.hasUnsavedChanges) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: Text(
          AppStrings.editorExitConfirm,
          style: AppTextStyles.titleMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.rubyLight),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _saveDesign(BuildContext context) async {
    final result = await _persistCurrentDesign(context);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickSlashFromContext(context, AppStrings.editorSaved),
          ),
        ),
      );
    } else if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  Future<void> _orderNow(BuildContext context) async {
    final catalog = ref.read(configuratorCatalogProvider).valueOrNull;
    final editor = ref.read(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    if (catalog != null) {
      for (final t in catalog.templates) {
        if (t.id == editor.configuratorTemplateId) {
          final message = notifier.validateConfiguratorForOrder(t);
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            return;
          }
          break;
        }
      }
    }

    final result = await _persistCurrentDesign(context);
    if (!mounted) return;
    if (!result.success) {
      if (result.message != null && result.message!.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message!)),
        );
      }
      return;
    }
    final updatedEditor = ref.read(editorProvider);
    context.push(
      '/order/summary',
      extra: OrderDesignDraft(
        designId: result.designId,
        name: updatedEditor.designName.trim().isEmpty
            ? 'Current design'
            : updatedEditor.designName,
        garmentType: updatedEditor.garmentType,
        primaryColour: _toHex(updatedEditor.primaryColour),
        accentColour: _toHex(updatedEditor.accentColour),
        fabricId: updatedEditor.selectedFabricId,
        fabricQuality: updatedEditor.fabricQuality,
        patternId: updatedEditor.selectedPatternId,
        mannequinId: updatedEditor.mannequinId,
        configuratorSummary: updatedEditor.configuratorSummary,
        accessoryIds: updatedEditor.selectedAccessoryIds,
        accessoriesSummary: updatedEditor.accessoriesSummary.isEmpty
            ? null
            : updatedEditor.accessoriesSummary,
      ),
    );
  }

  Future<SaveDesignResult> _persistCurrentDesign(BuildContext context) async {
    final notifier = ref.read(editorProvider.notifier);
    final editor = ref.read(editorProvider);
    final name = await showDialog<String?>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _SaveDesignNameDialog(
        initialName: editor.designName.trim(),
      ),
    );
    if (!mounted) {
      return const SaveDesignResult(success: false);
    }
    if (name == null) {
      return const SaveDesignResult(success: false);
    }
    if (name.trim().isEmpty) {
      return const SaveDesignResult(
        success: false,
        message: 'Design name is required.',
      );
    }
    return notifier.saveDesign(
      forceName: name.trim(),
      composePreviewBytes: await _captureHeroPng(),
    );
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _showShareOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.stone,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share image'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareImageOs(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('Save image'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _saveHeroImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Share to community'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareToCommunity(context);
                },
              ),
              if (ref.read(editorProvider).remoteDesignId?.trim().isNotEmpty ==
                  true)
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Publish & earn'),
                  subtitle: const Text('List on orderable Showcase'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _publishToShowcase(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareImageOs(BuildContext context) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final bytes = await _captureHeroPng(pixelRatio: 3.2);
      if (bytes == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture design preview.')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/lolipants-design-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My Lolipants design');
    } finally {
      if (mounted) _sharing = false;
    }
  }

  Future<void> _saveHeroImage(BuildContext context) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final bytes = await _captureHeroPng(pixelRatio: 3.2);
      if (bytes == null || !mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture design preview.')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/lolipants-design-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    } finally {
      if (mounted) _sharing = false;
    }
  }

  Future<void> _publishToShowcase(BuildContext context) async {
    if (_sharing) return;
    _sharing = true;
    try {
      var editor = ref.read(editorProvider);
      var designId = editor.remoteDesignId?.trim();
      if (designId == null || designId.isEmpty) {
        final saved = await _persistCurrentDesign(context);
        if (!mounted || !saved.success) return;
        editor = ref.read(editorProvider);
        designId = editor.remoteDesignId?.trim();
      }
      if (!mounted) return;
      if (designId == null || designId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save the design before publishing.')),
        );
        return;
      }
      final design = GarmentDesign(
        id: designId,
        name: editor.designName,
        garmentType: editor.garmentType.toString().split('.').last,
        primaryColour: _toHex(editor.primaryColour),
      );
      final confirmed = await showPublishShowcaseDialog(
        context,
        design: design,
        commissionPct: 10,
      );
      if (confirmed != true || !mounted) return;
      final result =
          await ref.read(designsRepositoryProvider).publishDesign(designId);
      if (!mounted) return;
      result.fold(
        (e) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              designErrorMessage(e, fallback: 'Could not publish design.'),
            ),
          ),
        ),
        (payload) => notifyShowcasePublishSuccess(
          ref,
          context,
          commissionPct: payload.commissionPct,
        ),
      );
    } finally {
      if (mounted) _sharing = false;
    }
  }

  Future<void> _shareToCommunity(BuildContext context) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final editor = ref.read(editorProvider);
      var bytes = await _captureHeroPng(pixelRatio: 3.2);
      bytes ??= await _loadBundledCatalogPngBytes(
        editor.selectedCatalogDesignPath.trim().isEmpty
            ? kDefaultCatalogDesignPath
            : editor.selectedCatalogDesignPath.trim(),
      );
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture design preview.')),
        );
        return;
      }
      final suggestedTag = editor.garmentType.toString().split('.').last;
      final prefill = CreatePostPrefill(
        body: editor.designName.trim().isEmpty
            ? 'Check out my new ${suggestedTag} design.'
            : 'Just designed ${editor.designName}.',
        imageBytes: bytes,
        imageFilename: 'design-${DateTime.now().millisecondsSinceEpoch}.png',
        tags: [suggestedTag, 'showcase'],
      );
      if (!mounted) return;
      final published =
          await context.push<bool>('/community/new-post', extra: prefill);
      if (published == true && mounted) {
        for (final tag in kNewsFeedTagFilterKeys) {
          ref.invalidate(feedPostsProvider(tag));
        }
      }
    } finally {
      if (mounted) _sharing = false;
    }
  }

  Future<Uint8List?> _loadBundledCatalogPngBytes(String assetPath) async {
    final path = assetPath.trim();
    if (!path.startsWith('assets/')) return null;
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } on Object {
      return null;
    }
  }

  Future<Uint8List?> _captureHeroPng({double pixelRatio = 2.5}) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      try {
        final ctx = _heroCaptureKey.currentContext;
        if (ctx == null) continue;
        final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = data?.buffer.asUint8List();
        if (bytes != null && bytes.lengthInBytes > 400) {
          return bytes;
        }
      } on Object {
        continue;
      }
    }
    return null;
  }
}

/// Owns [TextEditingController] for the save-name dialog so disposal runs after
/// the route removes the [TextField] (avoids framework `_dependents` assert).
class _SaveDesignNameDialog extends StatefulWidget {
  const _SaveDesignNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_SaveDesignNameDialog> createState() => _SaveDesignNameDialogState();
}

class _SaveDesignNameDialogState extends State<_SaveDesignNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.stone,
      title: Text('Save design', style: AppTextStyles.titleMedium),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Design name',
          hintText: 'Name shown in My designs',
        ),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) =>
            Navigator.of(context).pop<String?>(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<String?>(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop<String?>(_controller.text.trim()),
          child: Text(AppStrings.editorSave, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}

class _HeroToolButtons extends StatelessWidget {
  const _HeroToolButtons({
    required this.editor,
    required this.onPalette,
    required this.onAddText,
    required this.onAddImage,
  });

  final EditorState editor;
  final VoidCallback onPalette;
  final VoidCallback onAddText;
  final VoidCallback onAddImage;

  static final _fabStyle = IconButton.styleFrom(
    visualDensity: VisualDensity.compact,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    padding: const EdgeInsets.all(6),
    minimumSize: const Size(40, 40),
  );

  @override
  Widget build(BuildContext context) {
    final showCasualTools = editor.activeTab == EditorTab.designs &&
        isCasualEditorContext(
          selectedCatalogDesignPath: editor.selectedCatalogDesignPath,
          catalogFilter: editor.catalogFilter,
        );

    Widget fab({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return IconButton.filledTonal(
        tooltip: tooltip,
        style: _fabStyle,
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
      );
    }

    return Positioned(
      bottom: 6,
      right: 6,
      child: showCasualTools
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                fab(
                  icon: Icons.text_fields,
                  tooltip: AppStrings.editorAddText,
                  onPressed: onAddText,
                ),
                const SizedBox(height: 6),
                fab(
                  icon: Icons.image_outlined,
                  tooltip: AppStrings.editorAddImage,
                  onPressed: onAddImage,
                ),
                const SizedBox(height: 6),
                fab(
                  icon: Icons.palette_outlined,
                  tooltip: AppStrings.editorTabFabric,
                  onPressed: onPalette,
                ),
              ],
            )
          : fab(
              icon: Icons.palette_outlined,
              tooltip: AppStrings.editorTabFabric,
              onPressed: onPalette,
            ),
    );
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.onBack,
    required this.onSave,
    required this.onOrder,
    required this.onShare,
    required this.onSizing,
    required this.saving,
    required this.heroMode,
    required this.onHeroModeChanged,
    this.aiLookEnabled = true,
  });

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onOrder;
  final VoidCallback onShare;
  final VoidCallback onSizing;
  final bool saving;
  final EditorHeroMode heroMode;
  final ValueChanged<EditorHeroMode> onHeroModeChanged;
  final bool aiLookEnabled;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 400;

    Widget modeControl() {
      return SegmentedButton<EditorHeroMode>(
        segments: [
          ButtonSegment<EditorHeroMode>(
            value: EditorHeroMode.compose,
            tooltip: AppStrings.editorHeroCompose,
            icon: const Icon(Icons.layers_outlined, size: 20),
            label: narrow ? null : Text(pickSlashFromContext(context, AppStrings.editorHeroCompose)),
          ),
          ButtonSegment<EditorHeroMode>(
            value: EditorHeroMode.look,
            tooltip: AppStrings.editorHeroAiLook,
            icon: const Icon(Icons.checkroom_outlined, size: 20),
            label: narrow ? null : Text(pickSlashFromContext(context, AppStrings.editorHeroAiLook)),
            enabled: aiLookEnabled,
          ),
        ],
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          backgroundColor: AppColors.stone,
          foregroundColor: AppColors.sand,
          selectedForegroundColor: AppColors.sand,
          selectedBackgroundColor: AppColors.ember,
          side: const BorderSide(color: AppColors.borderStrong),
        ),
        selected: {heroMode},
        onSelectionChanged: (next) {
          if (next.isEmpty) return;
          onHeroModeChanged(next.first);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: narrow
                  ? modeControl()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: modeControl(),
                    ),
            ),
          ),
          if (narrow)
            PopupMenuButton<String>(
              tooltip: 'More',
              color: AppColors.stone,
              onSelected: (id) {
                switch (id) {
                  case 'share':
                    onShare();
                  case 'save':
                    onSave?.call();
                  case 'sizing':
                    onSizing();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'sizing',
                  child: Row(
                    children: [
                      const Icon(Icons.straighten, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.sizingOptionsTooltip,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.ios_share, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Share to community',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'save',
                  child: Row(
                    children: [
                      const Icon(Icons.save_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text('Save', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.more_horiz),
              ),
            )
          else ...[
            IconButton(
              tooltip: AppStrings.sizingOptionsTooltip,
              onPressed: onSizing,
              icon: const Icon(Icons.straighten),
            ),
            IconButton(
              tooltip: 'Share to community',
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
            ),
            IconButton(
              onPressed: onSave,
              icon: const Icon(Icons.save_outlined),
            ),
          ],
          SizedBox(
            width: narrow ? 110 : 130,
            child: LolipantsButton(
              label: narrow ? 'Order' : 'Order / اطلب',
              onPressed: onOrder,
              loading: saving,
              fullWidth: false,
            ),
          ),
        ],
      ),
    );
  }
}
