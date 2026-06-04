import 'dart:async';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart' show Color, Offset, Size;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/editor/models/design_text_layer.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/models/print_placement.dart';

export 'package:lolipants/features/editor/models/print_placement.dart';
import 'package:lolipants/features/editor/models/garment_design_suggestion.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/constants/ai_look_prompt_suffix.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/bundled_fabric_catalog.dart';
import 'package:lolipants/features/editor/logic/catalog_design_gender_filter.dart';
import 'package:lolipants/features/editor/models/catalog_design_pick.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/data/configurator_metadata.dart';
import 'package:lolipants/features/editor/data/editor_design_restore.dart';
import 'package:lolipants/features/editor/utils/ai_colour_parse.dart';
import 'package:lolipants/features/editor/widgets/editor_resize_handle.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/logic/configurator_compat.dart';
import 'package:lolipants/features/editor/logic/configurator_gender.dart';
import 'package:lolipants/features/editor/logic/mannequin_gender.dart';
import 'package:lolipants/features/editor/logic/editor_print_reference.dart';
import 'package:lolipants/features/editor/logic/refined_look_source_key.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Editor interaction tools shown in the side rail.
enum EditorTool { colour, text, image, sizing }

/// Bottom panel tabs for the editor shell.
enum EditorTab { designs, build, wedding, ai }

/// Hero preview: schematic compose vs Gemini-refined look.
enum EditorHeroMode { compose, look }

/// Build tab style source: modular configurator vs bundled flat-lay catalogue.
enum EditorBuildStyleMode { configurator, catalog }

/// Legacy alias for the canonical [DesignTextLayer] model. Kept so existing
/// call sites keep compiling; new code should use [DesignTextLayer] directly.
typedef EditorTextLayer = DesignTextLayer;

/// Result payload for editor save attempts.
class SaveDesignResult {
  const SaveDesignResult({
    required this.success,
    this.message,
    this.designId,
  });

  final bool success;
  final String? message;
  final String? designId;
}

/// Result of Gemini look generation from the editor.
class GenerateLookResult {
  /// Creates result.
  const GenerateLookResult({required this.success, this.message});

  /// Whether a refined image URL was obtained.
  final bool success;

  /// Error detail when [success] is false.
  final String? message;
}

/// Local state for Phase 3A editor interactions.
class EditorState {
  const EditorState({
    required this.designName,
    required this.mannequinId,
    required this.garmentType,
    required this.primaryColour,
    required this.accentColour,
    required this.activeTool,
    required this.activeTab,
    required this.fabricQuality,
    required this.selectedFabricId,
    required this.availableFabrics,
    required this.selectedPatternId,
    required this.selectedEmbroideryId,
    required this.textLayers,
    required this.selectedTextLayerId,
    required this.isPrintOverlaySelected,
    required this.printImagePath,
    required this.sketchImagePath,
    required this.customMannequinImagePath,
    required this.selectedCatalogDesignPath,
    required this.catalogFilter,
    required this.aiLookUserPrompt,
    required this.printPlacement,
    required this.printOffsetX,
    required this.printOffsetY,
    required this.printScale,
    required this.isSaving,
    required this.remoteDesignId,
    required this.heroMode,
    required this.refinedLookUrl,
    required this.refinedLookSourceKey,
    required this.lookGenerating,
    required this.lookGenerationError,
    required this.hasUnsavedChanges,
    required this.buildStyleMode,
    required this.configuratorTemplateId,
    required this.configuratorSelections,
    required this.configuratorSummary,
    required this.configuratorAiLayerNotes,
    required this.activeConfiguratorSlotIndex,
    required this.selectedWeddingDressId,
    required this.weddingCategoryFilter,
    required this.weddingFulfillment,
    required this.rentalDays,
    required this.selectedAccessoryIds,
    required this.accessoriesSummary,
    required this.preferCatalogBuild,
    required this.pinnedBrowseCatalogPath,
  });

  factory EditorState.initial() {
    final useMensDefaults = kFeatureMens;
    return EditorState(
      designName: '',
      mannequinId:
          useMensDefaults ? 'standard_male' : kPresetCatalogMannequinId,
      garmentType: useMensDefaults ? 'thobe' : 'abaya',
      primaryColour: AppColors.teal,
      accentColour: AppColors.gold,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.build,
      fabricQuality: 'standard',
      selectedFabricId: '',
      availableFabrics: const <FabricOption>[],
      selectedPatternId: 'plain',
      selectedEmbroideryId: 'motif_1',
      textLayers: const <DesignTextLayer>[],
      selectedTextLayerId: null,
      isPrintOverlaySelected: false,
      printImagePath: null,
      sketchImagePath: null,
      customMannequinImagePath: null,
      selectedCatalogDesignPath: kDefaultCatalogDesignPath,
      catalogFilter: DesignCatalogFilter.all,
      aiLookUserPrompt: '',
      printPlacement: PrintPlacement.chest,
      printOffsetX: 0,
      printOffsetY: 0,
      printScale: 40,
      isSaving: false,
      remoteDesignId: null,
      heroMode: EditorHeroMode.compose,
      refinedLookUrl: null,
      refinedLookSourceKey: null,
      lookGenerating: false,
      lookGenerationError: null,
      hasUnsavedChanges: true,
      configuratorTemplateId: '',
      buildStyleMode: EditorBuildStyleMode.configurator,
      configuratorSelections: const {},
      configuratorSummary: '',
      configuratorAiLayerNotes: '',
      activeConfiguratorSlotIndex: 0,
      selectedWeddingDressId: null,
      weddingCategoryFilter: WeddingCategoryFilter.all,
      weddingFulfillment: WeddingFulfillment.rent,
      rentalDays: 3,
      selectedAccessoryIds: const [],
      accessoriesSummary: '',
      preferCatalogBuild: false,
      pinnedBrowseCatalogPath: null,
    );
  }

  final String designName;
  final String mannequinId;
  final String garmentType;
  final Color primaryColour;
  final Color accentColour;
  final EditorTool activeTool;
  final EditorTab activeTab;
  final String fabricQuality;
  final String selectedFabricId;
  final List<FabricOption> availableFabrics;
  final String selectedPatternId;
  final String selectedEmbroideryId;
  final List<DesignTextLayer> textLayers;
  final String? selectedTextLayerId;

  /// Whether the print graphic shows resize handles on the flat-lay hero.
  final bool isPrintOverlaySelected;

  final String? printImagePath;

  /// Local path or uploaded HTTPS URL for optional silhouette/sketch reference.
  final String? sketchImagePath;
  final String? customMannequinImagePath;

  /// Bundled flat-lay PNG path under `assets/images/designs/`.
  final String selectedCatalogDesignPath;

  /// Subsection of the bundled flat-lay catalogue in the bottom panel.
  final DesignCatalogFilter catalogFilter;

  /// User text for Gemini look generation (AI tab).
  final String aiLookUserPrompt;
  final PrintPlacement printPlacement;
  final double printOffsetX;
  final double printOffsetY;
  final double printScale;
  final bool isSaving;

  /// Server design id when editing a saved design or after first successful save.
  final String? remoteDesignId;

  /// Hero preview mode: vector compose vs refined AI image.
  final EditorHeroMode heroMode;

  /// Last Gemini-refined preview URL from `/ai/design-render`.
  final String? refinedLookUrl;

  /// Fingerprint of catalog path / configurator picks when [refinedLookUrl] was set.
  final String? refinedLookSourceKey;

  final bool lookGenerating;
  final String? lookGenerationError;

  /// True until [EditorNotifier.saveDesign] succeeds, or after local edits
  /// following a successful save / [loadDesign] baseline.
  final bool hasUnsavedChanges;

  /// Configurator templates vs bundled design catalogue.
  final EditorBuildStyleMode buildStyleMode;

  /// Active modular configurator template id (`configurator_templates.id`).
  final String configuratorTemplateId;

  /// Slot id → option id selections for the Build tab.
  final ConfiguratorSelections configuratorSelections;

  /// Human-readable summary for save / quote (Build tab).
  final String configuratorSummary;

  /// Explicit sleeve vs overlay semantics for AI look generation.
  final String configuratorAiLayerNotes;

  /// Active slot chip index in the unified design panel.
  final int activeConfiguratorSlotIndex;

  /// Selected catalogue dress on the Wedding tab.
  final String? selectedWeddingDressId;

  final WeddingCategoryFilter weddingCategoryFilter;
  final WeddingFulfillment weddingFulfillment;
  final int rentalDays;

  /// Garment order add-on accessory ids.
  final List<String> selectedAccessoryIds;

  /// Human-readable accessory labels for checkout summary.
  final String accessoriesSummary;

  /// When true, home/browse design picks stay in the catalogue build lane.
  final bool preferCatalogBuild;

  /// Catalogue ref to restore when [preferCatalogBuild] is set.
  final String? pinnedBrowseCatalogPath;

  bool get isWeddingTab => activeTab == EditorTab.wedding;

  /// True when the user has explicitly picked a fabric from the catalogue.
  bool get isFabricSelected => selectedFabricId.trim().isNotEmpty;

  /// Flat-lay design catalogue assets do not require a separate fabric pick.
  bool get requiresFabricSelection =>
      buildStyleMode != EditorBuildStyleMode.catalog;

  /// True when a stored AI look belongs to the current catalogue / configurator pick.
  bool get refinedLookMatchesCurrentDesign {
    final url = refinedLookUrl?.trim();
    if (url == null || url.isEmpty) return false;
    final bound = refinedLookSourceKey?.trim();
    if (bound == null || bound.isEmpty) return true;
    return bound == refinedLookSourceKeyForEditorState(this);
  }

  /// AI hero URL only when it matches the active design inputs.
  String? get displayRefinedLookUrl {
    if (!refinedLookMatchesCurrentDesign) return null;
    return refinedLookUrl?.trim();
  }

  EditorState copyWith({
    String? designName,
    String? mannequinId,
    String? garmentType,
    Color? primaryColour,
    Color? accentColour,
    EditorTool? activeTool,
    EditorTab? activeTab,
    String? fabricQuality,
    String? selectedFabricId,
    List<FabricOption>? availableFabrics,
    String? selectedPatternId,
    String? selectedEmbroideryId,
    List<DesignTextLayer>? textLayers,
    String? selectedTextLayerId,
    bool unsetSelectedTextLayerId = false,
    bool? isPrintOverlaySelected,
    String? printImagePath,
    String? sketchImagePath,
    String? customMannequinImagePath,
    String? selectedCatalogDesignPath,
    DesignCatalogFilter? catalogFilter,
    String? aiLookUserPrompt,
    PrintPlacement? printPlacement,
    double? printOffsetX,
    double? printOffsetY,
    double? printScale,
    bool? isSaving,
    String? remoteDesignId,
    EditorHeroMode? heroMode,
    String? refinedLookUrl,
    String? refinedLookSourceKey,
    bool unsetRefinedLook = false,
    bool? lookGenerating,
    String? lookGenerationError,
    bool unsetLookError = false,
    bool? hasUnsavedChanges,
    String? configuratorTemplateId,
    EditorBuildStyleMode? buildStyleMode,
    ConfiguratorSelections? configuratorSelections,
    String? configuratorSummary,
    String? configuratorAiLayerNotes,
    int? activeConfiguratorSlotIndex,
    String? selectedWeddingDressId,
    bool unsetSelectedWeddingDressId = false,
    WeddingCategoryFilter? weddingCategoryFilter,
    WeddingFulfillment? weddingFulfillment,
    int? rentalDays,
    List<String>? selectedAccessoryIds,
    String? accessoriesSummary,
    bool? preferCatalogBuild,
    String? pinnedBrowseCatalogPath,
    bool clearPinnedBrowseCatalogPath = false,
  }) {
    return EditorState(
      designName: designName ?? this.designName,
      mannequinId: mannequinId ?? this.mannequinId,
      garmentType: garmentType ?? this.garmentType,
      primaryColour: primaryColour ?? this.primaryColour,
      accentColour: accentColour ?? this.accentColour,
      activeTool: activeTool ?? this.activeTool,
      activeTab: activeTab ?? this.activeTab,
      fabricQuality: fabricQuality ?? this.fabricQuality,
      selectedFabricId: selectedFabricId ?? this.selectedFabricId,
      availableFabrics: availableFabrics ?? this.availableFabrics,
      selectedPatternId: selectedPatternId ?? this.selectedPatternId,
      selectedEmbroideryId: selectedEmbroideryId ?? this.selectedEmbroideryId,
      textLayers: textLayers ?? this.textLayers,
      selectedTextLayerId: unsetSelectedTextLayerId
          ? null
          : (selectedTextLayerId ?? this.selectedTextLayerId),
      isPrintOverlaySelected:
          isPrintOverlaySelected ?? this.isPrintOverlaySelected,
      printImagePath: printImagePath ?? this.printImagePath,
      sketchImagePath: sketchImagePath ?? this.sketchImagePath,
      customMannequinImagePath:
          customMannequinImagePath ?? this.customMannequinImagePath,
      selectedCatalogDesignPath:
          selectedCatalogDesignPath ?? this.selectedCatalogDesignPath,
      catalogFilter: catalogFilter ?? this.catalogFilter,
      aiLookUserPrompt: aiLookUserPrompt ?? this.aiLookUserPrompt,
      printPlacement: printPlacement ?? this.printPlacement,
      printOffsetX: printOffsetX ?? this.printOffsetX,
      printOffsetY: printOffsetY ?? this.printOffsetY,
      printScale: printScale ?? this.printScale,
      isSaving: isSaving ?? this.isSaving,
      remoteDesignId: remoteDesignId ?? this.remoteDesignId,
      heroMode: heroMode ?? this.heroMode,
      refinedLookUrl:
          unsetRefinedLook ? null : (refinedLookUrl ?? this.refinedLookUrl),
      refinedLookSourceKey: unsetRefinedLook
          ? null
          : (refinedLookSourceKey ?? this.refinedLookSourceKey),
      lookGenerating: lookGenerating ?? this.lookGenerating,
      lookGenerationError: unsetLookError
          ? null
          : (lookGenerationError ?? this.lookGenerationError),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      configuratorTemplateId:
          configuratorTemplateId ?? this.configuratorTemplateId,
      buildStyleMode: buildStyleMode ?? this.buildStyleMode,
      configuratorSelections:
          configuratorSelections ?? this.configuratorSelections,
      configuratorSummary: configuratorSummary ?? this.configuratorSummary,
      configuratorAiLayerNotes:
          configuratorAiLayerNotes ?? this.configuratorAiLayerNotes,
      activeConfiguratorSlotIndex:
          activeConfiguratorSlotIndex ?? this.activeConfiguratorSlotIndex,
      selectedWeddingDressId: unsetSelectedWeddingDressId
          ? null
          : (selectedWeddingDressId ?? this.selectedWeddingDressId),
      weddingCategoryFilter:
          weddingCategoryFilter ?? this.weddingCategoryFilter,
      weddingFulfillment: weddingFulfillment ?? this.weddingFulfillment,
      rentalDays: rentalDays ?? this.rentalDays,
      selectedAccessoryIds:
          selectedAccessoryIds ?? this.selectedAccessoryIds,
      accessoriesSummary: accessoriesSummary ?? this.accessoriesSummary,
      preferCatalogBuild: preferCatalogBuild ?? this.preferCatalogBuild,
      pinnedBrowseCatalogPath: clearPinnedBrowseCatalogPath
          ? null
          : (pinnedBrowseCatalogPath ?? this.pinnedBrowseCatalogPath),
    );
  }
}

/// Phase 3A editor provider for shell-level interactions.
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier(this.ref) : super(EditorState.initial());

  final Ref ref;

  EditorTextLayer? get selectedTextLayer {
    final id = state.selectedTextLayerId;
    if (id == null) return null;
    for (final layer in state.textLayers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  void setDesignName(String value) {
    state = state.copyWith(designName: value, hasUnsavedChanges: true);
  }

  void setMannequin(String id) {
    if (state.buildStyleMode == EditorBuildStyleMode.catalog) {
      final sections = ref.read(mergedCatalogSectionsProvider(id));
      final paths = sections
          .expand((s) => s.$2.map((p) => p.ref))
          .toList(growable: false);
      var path = state.selectedCatalogDesignPath;
      if (paths.isNotEmpty && !paths.contains(path)) {
        path = paths.first;
      }
      final pathChanged =
          state.selectedCatalogDesignPath.trim() != path.trim();
      state = state.copyWith(
        mannequinId: id,
        selectedCatalogDesignPath: path,
        unsetRefinedLook: pathChanged,
        hasUnsavedChanges: true,
      );
      return;
    }
    state = state.copyWith(mannequinId: id, hasUnsavedChanges: true);
  }

  /// When [mannequinTemplates] is empty, switches to design-catalogue build.
  void syncBuildLaneForMannequin(List<ConfiguratorTemplate> mannequinTemplates) {
    if (state.preferCatalogBuild) {
      _ensureBrowseCatalogBuild();
      return;
    }
    if (mannequinTemplates.isNotEmpty) {
      if (state.buildStyleMode == EditorBuildStyleMode.catalog) return;
      ensureDefaultConfiguratorTemplate(mannequinTemplates);
      return;
    }
    if (state.activeTab == EditorTab.wedding) {
      setTab(EditorTab.build);
    }
    if (state.heroMode == EditorHeroMode.look) {
      setHeroMode(EditorHeroMode.compose);
    }
    if (state.buildStyleMode != EditorBuildStyleMode.catalog) {
      enterCatalogBuildMode(state.mannequinId);
    }
  }

  void setCustomMannequinImagePath(String? path) {
    state = state.copyWith(
      customMannequinImagePath: path,
      hasUnsavedChanges: true,
    );
  }

  void setCatalogDesignPath(String assetPath) {
    final lookup = ref.read(designCatalogLookupProvider);
    final cmsId = cmsDesignCatalogId(assetPath);
    final cmsGarment =
        cmsId != null ? lookup[cmsId]?.garmentType?.trim() : null;
    final isCasual = isCasualCatalogDesignPath(assetPath) ||
        (cmsGarment != null && kCasualGarmentTypes.contains(cmsGarment));
    final isLook = isRenderedCatalogLookPath(assetPath);
    final fromPath = garmentTypeFromCatalogDesignPathName(assetPath);
    final resolvedGarment = (cmsGarment != null && cmsGarment.isNotEmpty)
        ? cmsGarment
        : (fromPath != null && fromPath.isNotEmpty)
            ? fromPath
            : isCasual
                ? garmentTypeFromCatalogDesignPath(assetPath)
                : isLook
                    ? state.garmentType
                    : null;
    final customizable = isCasualBasicFlatlayPath(assetPath);
    final pathChanged =
        state.selectedCatalogDesignPath.trim() != assetPath.trim();
    state = state.copyWith(
      selectedCatalogDesignPath: assetPath,
      buildStyleMode: EditorBuildStyleMode.catalog,
      garmentType: resolvedGarment ?? state.garmentType,
      heroMode: EditorHeroMode.compose,
      unsetRefinedLook: pathChanged,
      hasUnsavedChanges: true,
      textLayers: customizable ? state.textLayers : const [],
      printImagePath: customizable ? state.printImagePath : null,
      selectedTextLayerId: customizable ? state.selectedTextLayerId : null,
      isPrintOverlaySelected:
          customizable ? state.isPrintOverlaySelected : false,
    );
    if (isCasual && state.buildStyleMode != EditorBuildStyleMode.catalog) {
      loadFabrics();
    }
  }

  void setCatalogFilter(DesignCatalogFilter filter) {
    final sections = bundledCatalogSectionsForMannequin(
      state.mannequinId,
      catalogFilter: filter,
    );
    var path = state.selectedCatalogDesignPath;
    if (sections.isNotEmpty) {
      final visible = sections.expand((e) => e.$2.map((p) => p.ref)).toSet();
      if (!visible.contains(path)) {
        path = sections.first.$2.first.ref;
      }
    }
    final isCasual =
        filter == DesignCatalogFilter.casual || isCasualCatalogDesignPath(path);
    final pathChanged = state.selectedCatalogDesignPath.trim() != path.trim();
    state = state.copyWith(
      catalogFilter: filter,
      selectedCatalogDesignPath: path,
      buildStyleMode: EditorBuildStyleMode.catalog,
      heroMode: EditorHeroMode.compose,
      unsetRefinedLook: pathChanged,
      garmentType:
          isCasual ? garmentTypeFromCatalogDesignPath(path) : state.garmentType,
      hasUnsavedChanges: true,
    );
    if (isCasual) {
      loadFabrics();
    }
  }

  void setAiLookUserPrompt(String value) {
    state = state.copyWith(aiLookUserPrompt: value, hasUnsavedChanges: true);
  }

  void setPrimaryColour(Color colour) {
    final clearLook = state.buildStyleMode == EditorBuildStyleMode.configurator;
    state = state.copyWith(
      primaryColour: colour,
      accentColour: colour,
      unsetRefinedLook: clearLook,
      hasUnsavedChanges: true,
    );
  }

  void setAccentColour(Color colour) {
    state = state.copyWith(
      accentColour: colour,
      unsetRefinedLook: state.buildStyleMode == EditorBuildStyleMode.configurator,
      hasUnsavedChanges: true,
    );
  }

  void setTool(EditorTool tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setTab(EditorTab tab) {
    var next = tab;
    if (tab == EditorTab.designs || tab == EditorTab.build) {
      next = EditorTab.build;
    }
    if (tab == EditorTab.ai && !kFeatureAiEditorTab) {
      next = EditorTab.build;
    }
    if (tab == EditorTab.wedding && !kFeatureWeddingTab) {
      next = EditorTab.build;
    }
    state = state.copyWith(activeTab: next);
  }

  void setConfiguratorSlotIndex(int index) {
    state = state.copyWith(
      activeConfiguratorSlotIndex: index < 0 ? 0 : index,
    );
  }

  void setInitialTab(EditorTab tab) {
    setTab(tab);
  }

  void setWeddingDressId(String? dressId) {
    state = state.copyWith(selectedWeddingDressId: dressId);
  }

  void setSelectedAccessories({
    required List<String> ids,
    required String summary,
  }) {
    state = state.copyWith(
      selectedAccessoryIds: ids,
      accessoriesSummary: summary,
      hasUnsavedChanges: true,
    );
  }

  void clearAccessories() {
    state = state.copyWith(
      selectedAccessoryIds: const [],
      accessoriesSummary: '',
      hasUnsavedChanges: true,
    );
  }

  void setWeddingCategoryFilter(WeddingCategoryFilter filter) {
    state = state.copyWith(weddingCategoryFilter: filter);
  }

  void setWeddingFulfillment(WeddingFulfillment fulfillment) {
    state = state.copyWith(weddingFulfillment: fulfillment);
  }

  void setRentalDays(int days) {
    state = state.copyWith(rentalDays: days < 1 ? 1 : days);
  }

  void _ensureBrowseCatalogBuild() {
    final pinned = state.pinnedBrowseCatalogPath?.trim();
    if (pinned == null || pinned.isEmpty) return;
    if (state.buildStyleMode == EditorBuildStyleMode.catalog &&
        state.selectedCatalogDesignPath.trim() == pinned) {
      return;
    }
    setCatalogDesignPath(pinned);
    state = state.copyWith(
      preferCatalogBuild: true,
      pinnedBrowseCatalogPath: pinned,
      buildStyleMode: EditorBuildStyleMode.catalog,
    );
  }

  /// Applies [kDefaultConfiguratorTemplateId] when build has no valid template.
  void ensureDefaultConfiguratorTemplate(List<ConfiguratorTemplate> templates) {
    if (state.preferCatalogBuild) {
      _ensureBrowseCatalogBuild();
      return;
    }
    if (templates.isEmpty) {
      syncBuildLaneForMannequin(const []);
      return;
    }
    if (state.buildStyleMode == EditorBuildStyleMode.catalog) return;
    final current = state.configuratorTemplateId.trim();
    if (current.isNotEmpty) {
      final stillValid = templates.any((t) => t.id == current);
      if (stillValid && state.configuratorSelections.isNotEmpty) {
        _refreshConfiguratorDerivedFields(templates, current);
        return;
      }
      if (stillValid && state.configuratorSelections.isEmpty) {
        setConfiguratorTemplate(current, templates);
        return;
      }
    }
    final lane = mannequinGenderLane(state.mannequinId);
    final pick = preferredConfiguratorTemplateForGender(templates, lane);
    final preferred = pick?.id ??
        (templates.any((t) => t.id == kDefaultConfiguratorTemplateId)
            ? kDefaultConfiguratorTemplateId
            : templates.first.id);
    setConfiguratorTemplate(preferred, templates);
  }

  void _refreshConfiguratorDerivedFields(
    List<ConfiguratorTemplate> templates,
    String templateId,
  ) {
    ConfiguratorTemplate? template;
    for (final t in templates) {
      if (t.id == templateId) {
        template = t;
        break;
      }
    }
    if (template == null) return;

    final selections = state.configuratorSelections;
    final summary = configuratorSummaryText(
      template: template,
      selections: selections,
      designName: state.designName,
    );
    final aiLayerNotes = configuratorAiLayerNotesText(
      template: template,
      selections: selections,
    );
    if (summary == state.configuratorSummary &&
        aiLayerNotes == state.configuratorAiLayerNotes) {
      return;
    }
    state = state.copyWith(
      configuratorSummary: summary,
      configuratorAiLayerNotes: aiLayerNotes,
    );
  }

  /// Switches modular configurator template and resets slot picks.
  void setConfiguratorTemplate(
    String templateId,
    List<ConfiguratorTemplate> templates,
  ) {
    ConfiguratorTemplate? template;
    for (final t in templates) {
      if (t.id == templateId) {
        template = t;
        break;
      }
    }
    if (template == null) return;

    final selections = <String, String>{};
    for (final slot in template.slots) {
      if (slot.options.isEmpty) continue;
      selections[slot.id] = defaultConfiguratorOptionId(
        slot.slotKey,
        slot.options
            .map((o) => (id: o.id, optionKey: o.optionKey))
            .toList(growable: false),
      );
    }
    final summary = configuratorSummaryText(
      template: template,
      selections: selections,
      designName: state.designName,
    );
    final aiLayerNotes = configuratorAiLayerNotesText(
      template: template,
      selections: selections,
    );
    state = state.copyWith(
      configuratorTemplateId: templateId,
      configuratorSelections: selections,
      configuratorSummary: summary,
      configuratorAiLayerNotes: aiLayerNotes,
      garmentType: template.garmentType,
      buildStyleMode: EditorBuildStyleMode.configurator,
      preferCatalogBuild: false,
      clearPinnedBrowseCatalogPath: true,
      unsetRefinedLook: true,
      hasUnsavedChanges: true,
    );
  }

  /// Switches to bundled flat-lay catalogue designs for [mannequinId].
  void enterCatalogBuildMode(String mannequinId) {
    final sections = ref.read(mergedCatalogSectionsProvider(mannequinId));
    final paths =
        sections.expand((s) => s.$2.map((p) => p.ref)).toList(growable: false);
    var path = state.selectedCatalogDesignPath;
    if (paths.isNotEmpty && !paths.contains(path)) {
      path = paths.first;
    }
    state = state.copyWith(
      buildStyleMode: EditorBuildStyleMode.catalog,
      selectedCatalogDesignPath: path,
      heroMode: EditorHeroMode.compose,
      unsetRefinedLook: true,
      lookGenerationError: null,
      hasUnsavedChanges: true,
    );
  }

  /// Resets catalogue filter/selection while staying in design-catalogue mode.
  void resetCatalogBuild(String mannequinId) {
    final sections = ref.read(mergedCatalogSectionsProvider(mannequinId));
    final path = sections.isNotEmpty && sections.first.$2.isNotEmpty
        ? sections.first.$2.first.ref
        : kDefaultCatalogDesignPath;
    state = state.copyWith(
      catalogFilter: DesignCatalogFilter.all,
      selectedCatalogDesignPath: path,
      heroMode: EditorHeroMode.compose,
      unsetRefinedLook: true,
      lookGenerationError: null,
      hasUnsavedChanges: true,
    );
  }

  /// Clears modular build state (call when leaving the editor).
  void resetConfigurator() {
    state = state.copyWith(
      configuratorTemplateId: '',
      configuratorSelections: const {},
      configuratorSummary: '',
      configuratorAiLayerNotes: '',
      activeConfiguratorSlotIndex: 0,
    );
  }

  /// Resets AI colours and restores default modest abaya slot picks.
  void resetConfiguratorBuild(List<ConfiguratorTemplate> templates) {
    final initial = EditorState.initial();
    state = state.copyWith(
      primaryColour: initial.primaryColour,
      accentColour: initial.primaryColour,
      activeTab: EditorTab.build,
      heroMode: EditorHeroMode.compose,
      unsetRefinedLook: true,
      lookGenerationError: null,
      buildStyleMode: EditorBuildStyleMode.configurator,
      hasUnsavedChanges: true,
    );
    if (templates.isEmpty) {
      state = state.copyWith(
        configuratorTemplateId: '',
        configuratorSelections: const {},
        configuratorSummary: '',
        configuratorAiLayerNotes: '',
      );
      return;
    }
    final lane = mannequinGenderLane(state.mannequinId);
    final pick = preferredConfiguratorTemplateForGender(templates, lane);
    final preferred = pick?.id ??
        (templates.any((t) => t.id == kDefaultConfiguratorTemplateId)
            ? kDefaultConfiguratorTemplateId
            : templates.first.id);
    // Must apply defaults directly — [ensureDefaultConfiguratorTemplate] skips
    // when selections are already set.
    setConfiguratorTemplate(preferred, templates);
  }

  /// Records one slot option and refreshes the build summary.
  void setConfiguratorOption({
    required ConfiguratorTemplate template,
    required String slotId,
    required String optionId,
  }) {
    final selections = resolveConfiguratorConflicts(
      template: template,
      selections: state.configuratorSelections,
      slotId: slotId,
      optionId: optionId,
    );
    final activeCount = activeConfiguratorSlots(
      template: template,
      selections: selections,
    ).length;
    final clampedIndex = activeCount == 0
        ? 0
        : state.activeConfiguratorSlotIndex.clamp(0, activeCount - 1);
    final summary = configuratorSummaryText(
      template: template,
      selections: selections,
      designName: state.designName,
    );
    final aiLayerNotes = configuratorAiLayerNotesText(
      template: template,
      selections: selections,
    );
    final beforeKey = refinedLookSourceKeyForEditorState(state);
    final nextState = state.copyWith(
      configuratorSelections: selections,
      configuratorSummary: summary,
      configuratorAiLayerNotes: aiLayerNotes,
      activeConfiguratorSlotIndex: clampedIndex,
      hasUnsavedChanges: true,
    );
    final afterKey = refinedLookSourceKeyForEditorState(nextState);
    state = nextState.copyWith(
      unsetRefinedLook: beforeKey != afterKey,
    );
  }

  /// Validates required configurator slots; returns user-facing message or null.
  String? validateConfiguratorForOrder(ConfiguratorTemplate template) {
    return configuratorRequiredSlotsMessage(
      template: template,
      selections: state.configuratorSelections,
    );
  }

  void setFabricQuality(String quality) {
    state = state.copyWith(fabricQuality: quality, hasUnsavedChanges: true);
  }

  void setFabric(String fabricId) {
    if (state.buildStyleMode == EditorBuildStyleMode.configurator &&
        state.selectedFabricId.trim() != fabricId.trim()) {
      state = state.copyWith(
        selectedFabricId: fabricId,
        unsetRefinedLook: true,
        hasUnsavedChanges: true,
      );
      return;
    }
    state = state.copyWith(selectedFabricId: fabricId, hasUnsavedChanges: true);
  }

  /// Clears persisted editor session (prints, saved id, configurator) for a
  /// brand-new design. Call before [loadPreset] when opening `/editor` without
  /// a [GarmentDesign].
  void beginNewDesign({
    String? mannequinId,
    String? customMannequinImagePath,
  }) {
    final initial = EditorState.initial();
    final trimmedMannequin = mannequinId?.trim();
    final trimmedCustom = customMannequinImagePath?.trim();
    state = EditorState(
      designName: initial.designName,
      mannequinId: (trimmedMannequin != null && trimmedMannequin.isNotEmpty)
          ? trimmedMannequin
          : initial.mannequinId,
      garmentType: initial.garmentType,
      primaryColour: initial.primaryColour,
      accentColour: initial.accentColour,
      activeTool: initial.activeTool,
      activeTab: initial.activeTab,
      fabricQuality: initial.fabricQuality,
      selectedFabricId: initial.selectedFabricId,
      availableFabrics: initial.availableFabrics,
      selectedPatternId: initial.selectedPatternId,
      selectedEmbroideryId: initial.selectedEmbroideryId,
      textLayers: const <DesignTextLayer>[],
      selectedTextLayerId: null,
      isPrintOverlaySelected: false,
      printImagePath: null,
      sketchImagePath: null,
      customMannequinImagePath:
          (trimmedCustom != null && trimmedCustom.isNotEmpty)
              ? trimmedCustom
              : null,
      selectedCatalogDesignPath: initial.selectedCatalogDesignPath,
      catalogFilter: initial.catalogFilter,
      aiLookUserPrompt: '',
      printPlacement: initial.printPlacement,
      printOffsetX: initial.printOffsetX,
      printOffsetY: initial.printOffsetY,
      printScale: initial.printScale,
      isSaving: false,
      remoteDesignId: null,
      heroMode: EditorHeroMode.compose,
      refinedLookUrl: null,
      refinedLookSourceKey: null,
      lookGenerating: false,
      lookGenerationError: null,
      hasUnsavedChanges: false,
      configuratorTemplateId: '',
      buildStyleMode: EditorBuildStyleMode.configurator,
      configuratorSelections: const {},
      configuratorSummary: '',
      configuratorAiLayerNotes: '',
      activeConfiguratorSlotIndex: 0,
      selectedWeddingDressId: initial.selectedWeddingDressId,
      weddingCategoryFilter: initial.weddingCategoryFilter,
      weddingFulfillment: initial.weddingFulfillment,
      rentalDays: initial.rentalDays,
      selectedAccessoryIds: initial.selectedAccessoryIds,
      accessoriesSummary: initial.accessoriesSummary,
      preferCatalogBuild: false,
      pinnedBrowseCatalogPath: null,
    );
  }

  /// Opens the editor from home/browse with mannequin + catalogue design pinned.
  void bootstrapBrowseDesign({
    required EditorPresetArgs preset,
    String? mannequinId,
    String? customMannequinImagePath,
  }) {
    beginNewDesign(
      mannequinId: mannequinId,
      customMannequinImagePath: customMannequinImagePath,
    );
    loadPreset(preset);
    final path = preset.catalogDesignPath?.trim() ?? '';
    if (!isEditorCatalogDesignRef(path)) return;
    state = state.copyWith(
      preferCatalogBuild: true,
      pinnedBrowseCatalogPath: path,
      buildStyleMode: EditorBuildStyleMode.catalog,
    );
    _ensureBrowseCatalogBuild();
  }

  /// Applies a regional preset (garment + palette + optional fabric/pattern)
  /// to live editor state, then refreshes fabrics for the new garment type.
  void loadPreset(EditorPresetArgs args) {
    final trimmedCatalog = args.catalogDesignPath?.trim() ?? '';
    final catalogOk = isEditorCatalogDesignRef(trimmedCatalog);
    final presetId = args.presetId ?? '';
    final garment = args.garmentType ?? '';
    final isCasual =
        presetId.startsWith('casual_') || kCasualGarmentTypes.contains(garment);
    final nextFilter =
        isCasual ? DesignCatalogFilter.casual : DesignCatalogFilter.all;
    var nextCatalogPath = state.selectedCatalogDesignPath;
    if (catalogOk) {
      nextCatalogPath = trimmedCatalog;
    } else if (isCasual) {
      final casualSections = catalogSectionsFor(DesignCatalogFilter.casual);
      if (casualSections.isNotEmpty) {
        nextCatalogPath = casualSections.first.$2.first;
      }
    }
    final useCatalogLane = catalogOk || isCasual;
    state = state.copyWith(
      designName: args.designName ?? state.designName,
      garmentType: args.garmentType ?? state.garmentType,
      primaryColour: args.primaryColour ?? state.primaryColour,
      accentColour: args.accentColour ?? state.accentColour,
      selectedFabricId: args.fabricId ?? state.selectedFabricId,
      selectedPatternId: args.patternId ?? state.selectedPatternId,
      mannequinId: args.mannequinId ?? state.mannequinId,
      selectedCatalogDesignPath: nextCatalogPath,
      catalogFilter: nextFilter,
      buildStyleMode: useCatalogLane
          ? EditorBuildStyleMode.catalog
          : state.buildStyleMode,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.build,
      remoteDesignId: null,
      unsetRefinedLook: true,
      heroMode: EditorHeroMode.compose,
      hasUnsavedChanges: true,
    );
    loadFabrics();
  }

  /// Hydrates editor state from a previously saved [GarmentDesign] so the
  /// user can edit it again.
  void loadDesign(GarmentDesign design) {
    final snapshot = editorDesignRestoreSnapshot(design);
    final meta = design.renderMetadata ?? const <String, dynamic>{};
    final configurator = parseConfiguratorFromRenderMetadata(
      design.renderMetadata,
    );
    final refinedLookUrl = aiRefinedLookUrlFromRenderMetadata(
      design.renderMetadata,
    );
    final refinedLookSourceKey = aiRefinedLookSourceKeyFromRenderMetadata(
      design.renderMetadata,
    );
    final buildStyleMode = _buildStyleModeFromRenderMetadata(
      design.renderMetadata,
    );
    final resolvedMannequin = editorMannequinIdFromDesign(design) ??
        EditorState.initial().mannequinId;
    final customMannequin = editorCustomMannequinFromRenderMetadata(meta);
    final aiPrompt = meta['aiLookUserPrompt']?.toString().trim() ?? '';
    final accessoriesBlock = meta['accessories'];
    var accessoryIds = const <String>[];
    var accessoriesSummary = '';
    if (accessoriesBlock is Map) {
      final rawIds = accessoriesBlock['ids'];
      if (rawIds is List) {
        accessoryIds = rawIds.map((e) => e.toString()).toList(growable: false);
      }
      accessoriesSummary = accessoriesBlock['summary']?.toString() ?? '';
    }
    state = state.copyWith(
      designName: design.name,
      garmentType: snapshot.garmentType,
      primaryColour: _parseHexColor(design.primaryColour),
      accentColour:
          design.accentColour != null && design.accentColour!.isNotEmpty
              ? _parseHexColor(design.accentColour!)
              : _parseHexColor(design.primaryColour),
      selectedFabricId: design.fabricId ?? state.selectedFabricId,
      fabricQuality: design.fabricQuality ?? state.fabricQuality,
      selectedPatternId: design.patternId ?? state.selectedPatternId,
      printImagePath: isEditorReferencePrintImage(
            printPathOrUrl: design.printImageUrl,
            catalogDesignPath: snapshot.catalogDesignPath,
            renderMetadata: meta,
          )
          ? null
          : design.printImageUrl,
      sketchImagePath: design.sketchImageUrl,
      printPlacement: snapshot.printPlacement,
      printOffsetX: snapshot.printOffsetX,
      printOffsetY: snapshot.printOffsetY,
      printScale: snapshot.printScale,
      textLayers: snapshot.textLayers,
      mannequinId: resolvedMannequin,
      customMannequinImagePath: customMannequin,
      aiLookUserPrompt: aiPrompt,
      remoteDesignId: design.id,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.build,
      selectedCatalogDesignPath: snapshot.catalogDesignPath,
      catalogFilter: snapshot.isCasual
          ? DesignCatalogFilter.casual
          : DesignCatalogFilter.all,
      configuratorTemplateId: configurator.templateId ?? '',
      configuratorSelections: configurator.selections,
      configuratorSummary: configurator.summary ?? '',
      configuratorAiLayerNotes: configurator.aiLayerNotes ?? '',
      buildStyleMode: buildStyleMode,
      refinedLookUrl: refinedLookUrl,
      refinedLookSourceKey: refinedLookSourceKey,
      isPrintOverlaySelected: false,
      unsetSelectedTextLayerId: true,
      selectedAccessoryIds: accessoryIds,
      accessoriesSummary: accessoriesSummary,
      hasUnsavedChanges: false,
    );
    final showLook = state.displayRefinedLookUrl != null;
    state = state.copyWith(
      heroMode: showLook ? EditorHeroMode.look : EditorHeroMode.compose,
    );
    loadFabrics();
  }

  Future<void> loadFabrics() async {
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.getFabricsForGarmentType(state.garmentType);
    result.fold(
      (_) {
        final bundled = bundledFabricOptionsForGarment(state.garmentType);
        if (bundled.isEmpty) return;
        state = state.copyWith(availableFabrics: bundled);
      },
      (fabrics) {
        if (fabrics.isEmpty) return;
        final fabricIds = fabrics.map((e) => e.id).toList(growable: false);
        final selected = fabricIds.contains(state.selectedFabricId)
            ? state.selectedFabricId
            : '';
        state = state.copyWith(
          availableFabrics: fabrics,
          selectedFabricId: selected,
        );
      },
    );
  }

  void setPattern(String patternId) {
    state = state.copyWith(
      selectedPatternId: patternId,
      hasUnsavedChanges: true,
    );
  }

  void setEmbroidery(String embroideryId) {
    state = state.copyWith(
      selectedEmbroideryId: embroideryId,
      hasUnsavedChanges: true,
    );
  }

  /// Applies AI suggestion colours, fabric, and pattern to live editor state.
  void applyAiSuggestion(GarmentDesignSuggestion suggestion) {
    final primary = _parseHexColor(suggestion.primaryColour);
    final accent = (suggestion.accentColour != null &&
            suggestion.accentColour!.trim().isNotEmpty)
        ? _parseHexColor(suggestion.accentColour!)
        : state.accentColour;

    final fabrics =
        state.availableFabrics.map((e) => e.id).toList(growable: false);
    const fabricAliases = <String, String>{
      'cotton': 'cotton',
      'cotton blend': 'cotton',
      'linen': 'linen',
      'flax': 'linen',
      'silk': 'silk',
      'satin': 'silk',
      'crepe': 'crepe',
      'crape': 'crepe',
      'chiffon': 'chiffon',
      'sheer': 'chiffon',
    };
    var fabricId = state.selectedFabricId;
    final fid = _normalizeToken(suggestion.fabricId);
    if (fid != null && fid.isNotEmpty) {
      if (fabricAliases.containsKey(fid)) {
        fabricId = fabricAliases[fid]!;
      } else {
        final matched = _bestTokenMatch(fid, fabrics);
        if (matched != null) {
          fabricId = matched;
        }
      }
    }

    const patterns = <String>[
      'geometric',
      'stripe',
      'plain',
      'arabesque',
      'floral',
      'embroidered',
    ];
    const patternAliases = <String, String>{
      'geo': 'geometric',
      'geometric': 'geometric',
      'geometry': 'geometric',
      'stripe': 'stripe',
      'striped': 'stripe',
      'line': 'stripe',
      'plain': 'plain',
      'solid': 'plain',
      'minimal': 'plain',
      'arabesque': 'arabesque',
      'islamic': 'arabesque',
      'floral': 'floral',
      'flower': 'floral',
      'embroidered': 'embroidered',
      'embroidery': 'embroidered',
    };
    var patternId = state.selectedPatternId;
    final pid = _normalizeToken(suggestion.patternId);
    if (pid != null && pid.isNotEmpty) {
      if (patternAliases.containsKey(pid)) {
        patternId = patternAliases[pid]!;
      } else {
        final matched = _bestTokenMatch(pid, patterns);
        if (matched != null) {
          patternId = matched;
        }
      }
    }

    state = state.copyWith(
      primaryColour: primary,
      accentColour: accent,
      selectedFabricId: fabricId,
      selectedPatternId: patternId,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.build,
      hasUnsavedChanges: true,
    );
  }

  Color _parseHexColor(String hex) {
    return parseAiColour(hex, fallback: state.primaryColour);
  }

  String? _normalizeToken(String? value) {
    if (value == null) return null;
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  String? _bestTokenMatch(String input, List<String> options) {
    for (final option in options) {
      if (input == option) return option;
    }
    for (final option in options) {
      if (input.contains(option) || option.contains(input)) {
        return option;
      }
    }
    final words = input.split(' ');
    for (final word in words) {
      for (final option in options) {
        if (word == option || option.contains(word) || word.contains(option)) {
          return option;
        }
      }
    }
    return null;
  }

  void addTextLayer(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final layer = DesignTextLayer(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: trimmed,
      fontFamily: 'Poppins',
      fontSize: 20,
      colour: AppColors.sand,
      placement: const Offset(0.5, 0.5),
    );
    state = state.copyWith(
      textLayers: [...state.textLayers, layer],
      selectedTextLayerId: layer.id,
      isPrintOverlaySelected: false,
      activeTool: EditorTool.text,
      activeTab: EditorTab.build,
      hasUnsavedChanges: true,
    );
  }

  void selectTextLayer(String id) {
    state = state.copyWith(
      selectedTextLayerId: id,
      isPrintOverlaySelected: false,
    );
  }

  void selectPrintOverlay() {
    state = state.copyWith(
      isPrintOverlaySelected: true,
      unsetSelectedTextLayerId: true,
    );
  }

  void clearOverlaySelection() {
    state = state.copyWith(
      isPrintOverlaySelected: false,
      unsetSelectedTextLayerId: true,
    );
  }

  void updateSelectedText({
    String? fontFamily,
    double? fontSize,
    Color? colour,
    Offset? placement,
    double? rotation,
  }) {
    final selectedId = state.selectedTextLayerId;
    if (selectedId == null) return;
    updateTextLayer(
      selectedId,
      fontFamily: fontFamily,
      fontSize: fontSize,
      colour: colour,
      placement: placement,
      rotation: rotation,
    );
  }

  void updateTextLayer(
    String layerId, {
    String? fontFamily,
    double? fontSize,
    Color? colour,
    Offset? placement,
    double? rotation,
  }) {
    final updated = <DesignTextLayer>[];
    for (final layer in state.textLayers) {
      if (layer.id == layerId) {
        updated.add(
          layer.copyWith(
            fontFamily: fontFamily,
            fontSize: fontSize,
            colour: colour,
            placement: placement,
            rotation: rotation,
          ),
        );
      } else {
        updated.add(layer);
      }
    }
    state = state.copyWith(textLayers: updated, hasUnsavedChanges: true);
  }

  void removeSelectedText() {
    final selectedId = state.selectedTextLayerId;
    if (selectedId == null) return;
    state = state.copyWith(
      textLayers: state.textLayers.where((l) => l.id != selectedId).toList(),
      unsetSelectedTextLayerId: true,
      hasUnsavedChanges: true,
    );
  }

  void setPrintImagePath(String? path) {
    final hasPrint = path != null && path.trim().isNotEmpty;
    state = state.copyWith(
      printImagePath: path,
      isPrintOverlaySelected: hasPrint,
      unsetSelectedTextLayerId: hasPrint,
      activeTool: EditorTool.image,
      hasUnsavedChanges: true,
    );
    if (path != null && path.isNotEmpty && !path.startsWith('http')) {
      _uploadAssetPath(
        path,
        onUrl: (url) => state = state.copyWith(printImagePath: url),
      );
    }
  }

  void setSketchImagePath(String? path) {
    state = state.copyWith(
      sketchImagePath: path,
      activeTool: EditorTool.image,
      hasUnsavedChanges: true,
    );
    if (path != null && path.isNotEmpty && !path.startsWith('http')) {
      _uploadAssetPath(
        path,
        onUrl: (url) => state = state.copyWith(sketchImagePath: url),
      );
    }
  }

  Future<void> _uploadAssetPath(
    String localPath, {
    required void Function(String url) onUrl,
  }) async {
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.uploadPrintImage(filePath: localPath);
    result.fold((_) {}, onUrl);
  }

  void adjustPrintScaleByHandle(EditorResizeHandle handle, Offset delta) {
    if (delta == Offset.zero) return;
    final next = (state.printScale + editorResizeScaleDelta(handle, delta))
        .clamp(20.0, 120.0);
    if (next == state.printScale) return;
    setPrintScale(next);
  }

  void adjustTextLayerSizeByHandle(
    String layerId,
    EditorResizeHandle handle,
    Offset delta,
  ) {
    DesignTextLayer? layer;
    for (final l in state.textLayers) {
      if (l.id == layerId) {
        layer = l;
        break;
      }
    }
    if (layer == null) return;
    final nextSize = (layer.fontSize + editorResizeFontDelta(handle, delta))
        .clamp(8.0, 96.0);
    updateTextLayer(layerId, fontSize: nextSize);
  }

  void setHeroMode(EditorHeroMode mode) {
    state = state.copyWith(heroMode: mode);
  }

  /// Ensures catalogue picks always open on Compose / layers, not AI Look.
  void ensureCatalogComposeHero() {
    if (state.buildStyleMode != EditorBuildStyleMode.catalog) return;
    if (state.heroMode == EditorHeroMode.compose) return;
    state = state.copyWith(heroMode: EditorHeroMode.compose);
  }

  void setPrintPlacement(PrintPlacement placement) {
    state = state.copyWith(
      printPlacement: placement,
      hasUnsavedChanges: true,
    );
  }

  void setPrintOffsetX(double value) {
    state = state.copyWith(printOffsetX: value, hasUnsavedChanges: true);
  }

  void setPrintOffsetY(double value) {
    state = state.copyWith(printOffsetY: value, hasUnsavedChanges: true);
  }

  void setPrintScale(double value) {
    state = state.copyWith(printScale: value, hasUnsavedChanges: true);
  }

  void nudgePrintOffset(Offset delta) {
    if (delta == Offset.zero) return;
    state = state.copyWith(
      printOffsetX: state.printOffsetX + delta.dx,
      printOffsetY: state.printOffsetY + delta.dy,
      hasUnsavedChanges: true,
    );
  }

  void nudgeTextLayerPlacement(
    String layerId,
    Offset pixelDelta,
    Size canvasSize,
  ) {
    if (pixelDelta == Offset.zero) return;
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return;
    DesignTextLayer? layer;
    for (final l in state.textLayers) {
      if (l.id == layerId) {
        layer = l;
        break;
      }
    }
    if (layer == null) return;
    final next = Offset(
      (layer.placement.dx + pixelDelta.dx / canvasSize.width).clamp(0.05, 0.95),
      (layer.placement.dy + pixelDelta.dy / canvasSize.height).clamp(0.1, 0.98),
    );
    if (next == layer.placement) return;
    updateTextLayer(layerId, placement: next);
  }

  /// True when AI render should use the flat-lay catalogue dress, not configurator compose.
  bool _isCatalogBuildForAi() =>
      state.buildStyleMode == EditorBuildStyleMode.catalog;

  /// Public CDN URL or uploaded bytes URL for [catalogPath] (per-design asset).
  Future<String?> _resolveCatalogFlatUrlForAi(
    String catalogPath,
    Future<String?> Function(List<int> bytes, String filename) uploadBytes,
  ) async {
    final trimmed = catalogPath.trim();
    if (trimmed.isEmpty) return null;

    if (isCmsDesignCatalogRef(trimmed)) {
      final lookup = ref.read(designCatalogLookupProvider);
      final cmsId = cmsDesignCatalogId(trimmed);
      final url = cmsId != null ? lookup[cmsId]?.imageUrl.trim() : null;
      if (url != null && url.isNotEmpty) return url;
    }

    final cdn = catalogImageNetworkUrl(trimmed);
    if (cdn != null && cdn.isNotEmpty) return cdn;

    final asset = bundledCatalogAssetPath(trimmed) ?? trimmed;
    if (!asset.startsWith('assets/')) return null;
    final raw = await rootBundle.load(asset);
    final bytes = raw.buffer.asUint8List();
    if (bytes.isEmpty) return null;
    final base = asset.split('/').last;
    final safeName = base.isNotEmpty ? base : 'catalog-flat.png';
    return uploadBytes(bytes, safeName);
  }

  String _garmentTypeForSave() {
    final path = state.selectedCatalogDesignPath.trim();
    final lookup = ref.read(designCatalogLookupProvider);
    final cmsId = cmsDesignCatalogId(path);
    if (cmsId != null) {
      final garment = lookup[cmsId]?.garmentType?.trim();
      if (garment != null && garment.isNotEmpty) return garment;
    }
    if (isCasualCatalogDesignPath(path) ||
        state.catalogFilter == DesignCatalogFilter.casual) {
      return garmentTypeFromCatalogDesignPath(path);
    }
    return state.garmentType;
  }

  Future<SaveDesignResult> saveDesign({
    String? forceName,
    Uint8List? composePreviewBytes,
  }) async {
    if (state.requiresFabricSelection && !state.isFabricSelected) {
      return const SaveDesignResult(
        success: false,
        message: 'Pick a fabric before saving.',
      );
    }
    final repo = ref.read(designsRepositoryProvider);
    var name = (forceName ?? state.designName).trim();
    if (name.isEmpty) {
      name = 'My look';
    }
    state = state.copyWith(isSaving: true, designName: name);

    Future<String?> uploadBytes(List<int> bytes, String filename) async {
      final r = await repo.uploadPrintBytes(bytes: bytes, filename: filename);
      return r.fold((_) => null, (u) => u);
    }

    Future<Uint8List?> loadBundle(String assetKey) async {
      try {
        final bd = await rootBundle.load(assetKey);
        return bd.buffer.asUint8List();
      } on Object {
        return null;
      }
    }

    final isCatalogBuild = _isCatalogBuildForAi();
    String? catalogFlatUrl;
    final catalogPath = state.selectedCatalogDesignPath.trim();
    if (isCatalogBuild && catalogPath.isNotEmpty) {
      catalogFlatUrl = await _resolveCatalogFlatUrlForAi(catalogPath, uploadBytes);
      if (catalogFlatUrl == null || catalogFlatUrl.isEmpty) {
        state = state.copyWith(isSaving: false);
        return const SaveDesignResult(
          success: false,
          message: 'Could not resolve catalogue design image for AI.',
        );
      }
    }

    String? editorMannequinUrl;
    final custom = state.customMannequinImagePath?.trim();
    if (custom != null && custom.isNotEmpty) {
      if (custom.startsWith('http')) {
        editorMannequinUrl = custom;
      } else {
        final up = await repo.uploadPrintImage(filePath: custom);
        editorMannequinUrl = up.fold((_) => null, (u) => u);
        if (editorMannequinUrl == null) {
          state = state.copyWith(isSaving: false);
          return const SaveDesignResult(
            success: false,
            message: 'Could not upload custom mannequin photo.',
          );
        }
      }
    } else {
      final mPath = builtInMannequinAssetPath(state.mannequinId);
      if (mPath != null) {
        final raw = await loadBundle(mPath);
        if (raw != null && raw.isNotEmpty) {
          editorMannequinUrl = await uploadBytes(raw, 'mannequin-ref.png');
          if (editorMannequinUrl == null) {
            state = state.copyWith(isSaving: false);
            return const SaveDesignResult(
              success: false,
              message: 'Could not upload mannequin reference.',
            );
          }
        }
      }
    }

    String? configuratorComposeUrl;
    if (!isCatalogBuild &&
        composePreviewBytes != null &&
        composePreviewBytes.isNotEmpty) {
      configuratorComposeUrl = await uploadBytes(
        composePreviewBytes,
        'configurator-compose.png',
      );
      if (configuratorComposeUrl == null) {
        state = state.copyWith(isSaving: false);
        return const SaveDesignResult(
          success: false,
          message: 'Could not upload design preview for AI.',
        );
      }
    }

    // User artwork to print (separate from catalogue flat-lay reference).
    String? printArtworkUrl;
    final userPrint = state.printImagePath?.trim();
    if (userPrint != null && userPrint.isNotEmpty) {
      if (userPrint.startsWith('http')) {
        printArtworkUrl = userPrint;
      } else {
        final upload = await repo.uploadPrintImage(filePath: userPrint);
        final uploaded = upload.fold<String?>((e) {
          state = state.copyWith(isSaving: false);
          return null;
        }, (url) => url);
        if (uploaded == null) {
          return const SaveDesignResult(
            success: false,
            message: 'Could not upload print image.',
          );
        }
        printArtworkUrl = uploaded;
        state = state.copyWith(printImagePath: uploaded);
      }
    }

    if ((printArtworkUrl == null || printArtworkUrl.isEmpty) &&
        isCatalogBuild &&
        catalogFlatUrl != null &&
        catalogFlatUrl.isNotEmpty) {
      printArtworkUrl = catalogFlatUrl;
    } else if ((printArtworkUrl == null || printArtworkUrl.isEmpty) &&
        configuratorComposeUrl != null &&
        configuratorComposeUrl.isNotEmpty) {
      printArtworkUrl = configuratorComposeUrl;
    }

    String? sketchImageUrl = state.sketchImagePath?.trim();
    if (sketchImageUrl != null && sketchImageUrl.isEmpty) {
      sketchImageUrl = null;
    }
    if (sketchImageUrl != null && !sketchImageUrl.startsWith('http')) {
      final upload = await repo.uploadPrintImage(filePath: sketchImageUrl);
      final uploaded = upload.fold<String?>((e) {
        state = state.copyWith(isSaving: false);
        return null;
      }, (url) => url);
      if (uploaded == null) {
        return const SaveDesignResult(
          success: false,
          message: 'Could not upload sketch image.',
        );
      }
      sketchImageUrl = uploaded;
      state = state.copyWith(sketchImagePath: uploaded);
    }

    final garmentType = _garmentTypeForSave();

    final payload = <String, dynamic>{
      'name': name,
      'garmentType': garmentType,
      'primaryColour': _colorToHex(state.primaryColour),
      'accentColour': _colorToHex(state.accentColour),
      'fabricId': state.selectedFabricId,
      'fabricQuality': state.fabricQuality,
      'patternId': state.selectedPatternId,
      'printImageUrl': printArtworkUrl,
      'sketchImageUrl': sketchImageUrl,
      'printPlacement': state.printPlacement.name,
      'printOffsetX': state.printOffsetX,
      'printOffsetY': state.printOffsetY,
      'printScale': state.printScale,
      'mannequinId': _normalizedMannequinIdForApi(),
      'customMannequinImagePath': state.customMannequinImagePath,
      'renderMetadata': {
        'mannequinTemplateId': _resolveMannequinTemplateId(),
        'editorMannequinId': state.mannequinId.trim(),
        if (state.customMannequinImagePath != null &&
            state.customMannequinImagePath!.trim().isNotEmpty)
          'customMannequinImagePath': state.customMannequinImagePath!.trim(),
        'garmentType': garmentType,
        'primaryColour': _colorToHex(state.primaryColour),
        'accentColour': _colorToHex(state.accentColour),
        'fabricProfile': state.fabricQuality,
        'printImageUrl': printArtworkUrl,
        if (catalogFlatUrl != null && catalogFlatUrl.isNotEmpty)
          'catalogFlatImageUrl': catalogFlatUrl,
        'catalogDesignPath': state.selectedCatalogDesignPath,
        'printTransform': {
          'placement': state.printPlacement.name,
          'x': state.printOffsetX,
          'y': state.printOffsetY,
          'scale': state.printScale,
        },
        'textLayers': state.textLayers
            .map(
              (layer) => {
                'text': layer.text,
                'fontFamily': layer.fontFamily,
                'fontSize': layer.fontSize,
                'colour': _colorToHex(layer.colour),
                'x': layer.placement.dx,
                'y': layer.placement.dy,
                'rotation': layer.rotation,
              },
            )
            .toList(growable: false),
        'exportTier': 'editor',
        'selectedCatalogDesignPath': state.selectedCatalogDesignPath,
        'buildStyleMode': isCatalogBuild
            ? EditorBuildStyleMode.catalog.name
            : state.buildStyleMode.name,
        'aiLookUserPrompt': state.aiLookUserPrompt.trim(),
        'aiLookPromptSuffix': kAiLookPromptSuffix,
        if (editorMannequinUrl != null && editorMannequinUrl.isNotEmpty)
          'editorMannequinImageUrl': editorMannequinUrl,
        if (configuratorComposeUrl != null && configuratorComposeUrl.isNotEmpty)
          'configuratorComposeImageUrl': configuratorComposeUrl,
        if (!isCatalogBuild && state.configuratorTemplateId.isNotEmpty)
          kConfiguratorMetadataKey: buildConfiguratorMetadataBlock(
            templateId: state.configuratorTemplateId,
            selections: state.configuratorSelections,
            summary: state.configuratorSummary,
            aiLayerNotes: state.configuratorAiLayerNotes,
          ),
        'aiRefinedLookUrl': state.refinedLookUrl?.trim(),
        if (state.refinedLookSourceKey?.trim().isNotEmpty ?? false)
          'aiRefinedLookSourceKey': state.refinedLookSourceKey!.trim(),
        if (state.selectedAccessoryIds.isNotEmpty)
          'accessories': {
            'ids': state.selectedAccessoryIds,
            'summary': state.accessoriesSummary,
          },
      },
      'textLayers': state.textLayers
          .map(
            (layer) => {
              'text': layer.text,
              'fontFamily': layer.fontFamily,
              'fontSize': layer.fontSize,
              'colour': _colorToHex(layer.colour),
              'x': layer.placement.dx,
              'y': layer.placement.dy,
              'rotation': layer.rotation,
            },
          )
          .toList(growable: false),
    };

    final existingId = state.remoteDesignId;
    final Either<AppException, GarmentDesign> resultEither =
        existingId != null && existingId.isNotEmpty
            ? await repo.updateDesign(id: existingId, payload: payload)
            : await repo.createDesign(payload: payload);

    state = state.copyWith(isSaving: false);
    return resultEither.fold(
      (e) => SaveDesignResult(
        success: false,
        message: designErrorMessage(e, fallback: 'Could not save design.'),
      ),
      (design) {
        ref.read(myDesignsProvider.notifier).reload();
        state = state.copyWith(
          remoteDesignId: design.id,
          garmentType: garmentType,
          hasUnsavedChanges: false,
        );
        if (kCasualGarmentTypes.contains(garmentType)) {
          loadFabrics();
        }
        return SaveDesignResult(
          success: true,
          designId: design.id,
        );
      },
    );
  }

  /// Persists [aiRefinedLookUrl] on the saved design without re-uploading assets.
  Future<void> _persistRefinedLookUrl(String url) async {
    final id = state.remoteDesignId?.trim();
    if (id == null || id.isEmpty) return;

    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final sourceKey = refinedLookSourceKeyForEditorState(state);
    final repo = ref.read(designsRepositoryProvider);
    final name =
        state.designName.trim().isEmpty ? 'My look' : state.designName.trim();
    final result = await repo.updateDesign(
      id: id,
      payload: {
        'name': name,
        'garmentType': _garmentTypeForSave(),
        'renderMetadata': {
          'aiRefinedLookUrl': trimmed,
          'aiRefinedLookSourceKey': sourceKey,
        },
      },
    );
    result.fold(
      (_) {},
      (_) {
        state = state.copyWith(hasUnsavedChanges: false);
      },
    );
  }

  /// Saves the current design, starts `/ai/design-render`, polls until complete.
  ///
  /// Pass [composePreviewBytes] (mannequin + configurator layers PNG) so Gemini
  /// can refine from the on-screen compose when no separate print is set.
  Future<GenerateLookResult> generateRefinedLook({
    Uint8List? composePreviewBytes,
  }) async {
    if (state.requiresFabricSelection && !state.isFabricSelected) {
      return const GenerateLookResult(
        success: false,
        message: 'Pick a fabric before refining.',
      );
    }
    state = state.copyWith(
      lookGenerating: true,
      unsetLookError: true,
    );
    final saved = await saveDesign(composePreviewBytes: composePreviewBytes);
    if (!saved.success || saved.designId == null) {
      final msg = saved.message ?? 'Save failed';
      state = state.copyWith(
        lookGenerating: false,
        lookGenerationError: msg,
      );
      return GenerateLookResult(success: false, message: msg);
    }

    final previewRepo = ref.read(renderPreviewRepositoryProvider);
    final start = await previewRepo.startRender(designId: saved.designId!);
    ref.invalidate(aiRenderQuotaProvider);
    if (start.isLeft()) {
      final msg = designErrorMessage(
        start.fold((l) => l, (_) => throw StateError('right')),
        fallback: 'Could not start render.',
      );
      state = state.copyWith(
        lookGenerating: false,
        lookGenerationError: msg,
      );
      return GenerateLookResult(success: false, message: msg);
    }

    final job = start.fold((_) => throw StateError('left'), (r) => r);
    final jobId = job.jobId;
    if (jobId.isEmpty) {
      const msg = 'Missing job id';
      state = state.copyWith(lookGenerating: false, lookGenerationError: msg);
      return const GenerateLookResult(success: false, message: msg);
    }

    for (var attempt = 0; attempt < 180; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final polled = await previewRepo.getRenderStatus(jobId: jobId);
      final exit = polled.fold(
        (e) {
          final msg =
              designErrorMessage(e, fallback: 'Could not load render status.');
          state = state.copyWith(
            lookGenerating: false,
            lookGenerationError: msg,
          );
          return GenerateLookResult(success: false, message: msg);
        },
        (j) {
          if (j.status == 'completed') {
            final url = j.artifacts['heroFrontUrl'];
            final renderMode = j.artifacts['renderMode'] ?? '';
            if (url != null && url.isNotEmpty) {
              final sourceKey = refinedLookSourceKeyForEditorState(state);
              if (renderMode == 'template_static_v1') {
                const msg =
                    'AI preview was unavailable. Showing your saved compose preview instead.';
                state = state.copyWith(
                  lookGenerating: false,
                  refinedLookUrl: url,
                  refinedLookSourceKey: sourceKey,
                  heroMode: EditorHeroMode.look,
                  lookGenerationError: msg,
                  hasUnsavedChanges: true,
                );
                return GenerateLookResult(success: false, message: msg);
              }
              state = state.copyWith(
                lookGenerating: false,
                refinedLookUrl: url,
                refinedLookSourceKey: sourceKey,
                heroMode: EditorHeroMode.look,
                unsetLookError: true,
                hasUnsavedChanges: true,
              );
              unawaited(_persistRefinedLookUrl(url));
              return const GenerateLookResult(success: true);
            }
            const msg = 'No preview URL in response';
            state = state.copyWith(
              lookGenerating: false,
              lookGenerationError: msg,
            );
            return const GenerateLookResult(success: false, message: msg);
          }
          if (j.status == 'failed') {
            var msg = j.error ?? 'Render failed';
            if (msg.contains('Design has no renderable preview source') ||
                msg.contains('no renderable preview')) {
              msg =
                  'Add a print or sketch, pick a catalogue mannequin with a preview, or configure AI preview on the server (GEMINI_API_KEY), then save and try again.';
            }
            state = state.copyWith(
              lookGenerating: false,
              lookGenerationError: msg,
            );
            return GenerateLookResult(success: false, message: msg);
          }
          return null;
        },
      );
      if (exit != null) return exit;
    }

    const msg = 'Timed out waiting for preview.';
    state = state.copyWith(
      lookGenerating: false,
      lookGenerationError: msg,
    );
    return const GenerateLookResult(success: false, message: msg);
  }

  String? _normalizedMannequinIdForApi() {
    final id = state.mannequinId.trim();
    if (id.isEmpty) return null;
    return canonicalMannequinIdForApi(id);
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  EditorBuildStyleMode _buildStyleModeFromRenderMetadata(
    Map<String, dynamic>? meta,
  ) {
    if (meta == null) return EditorBuildStyleMode.configurator;
    final raw = meta['buildStyleMode']?.toString().trim();
    if (raw == EditorBuildStyleMode.catalog.name) {
      return EditorBuildStyleMode.catalog;
    }
    if (meta['selectedStudioDesignId'] != null) {
      return EditorBuildStyleMode.catalog;
    }
    return EditorBuildStyleMode.configurator;
  }

  String _resolveMannequinTemplateId() {
    final id = state.mannequinId.toLowerCase();
    final garment = state.garmentType.toLowerCase();
    if (garment == 'abaya' ||
        id.contains('female') ||
        id.contains('curvy') ||
        id.contains('plus') ||
        id.contains('petite') ||
        id.contains('athletic')) {
      return 'female_abaya_v1';
    }
    if (garment == 'bisht') return 'unisex_bisht_v1';
    if (id.contains('male')) return 'male_thobe_v1';
    return 'default_thobe_v1';
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(ref),
);
