import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart' show Color, Offset, Size;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:lolipants/features/editor/data/configurator_defaults.dart';
import 'package:lolipants/features/editor/data/configurator_metadata.dart';
import 'package:lolipants/features/editor/data/editor_design_restore.dart';
import 'package:lolipants/features/editor/widgets/editor_resize_handle.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Editor interaction tools shown in the side rail.
enum EditorTool { colour, text, image, sizing }

/// Bottom panel tabs for the editor shell.
enum EditorTab { designs, build, wedding, ai }

/// Hero preview: schematic compose vs Gemini-refined look.
enum EditorHeroMode { compose, look }

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
    required this.lookGenerating,
    required this.lookGenerationError,
    required this.hasUnsavedChanges,
    required this.configuratorTemplateId,
    required this.configuratorSelections,
    required this.configuratorSummary,
    required this.selectedWeddingDressId,
    required this.weddingCategoryFilter,
    required this.weddingFulfillment,
    required this.rentalDays,
  });

  factory EditorState.initial() {
    final useMensDefaults = kFeatureMens;
    return EditorState(
      designName: '',
      mannequinId: useMensDefaults ? 'standard_male' : 'standard_female',
      garmentType: useMensDefaults ? 'thobe' : 'abaya',
      primaryColour: AppColors.teal,
      accentColour: AppColors.gold,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.designs,
      fabricQuality: 'standard',
      selectedFabricId: 'cotton',
      availableFabrics: const <FabricOption>[
        FabricOption(
          id: 'cotton',
          name: 'Cotton',
          nameAr: 'قطن',
          quality: 'standard',
          isAvailable: true,
        ),
        FabricOption(
          id: 'linen',
          name: 'Linen',
          nameAr: 'كتان',
          quality: 'standard',
          isAvailable: true,
        ),
      ],
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
      lookGenerating: false,
      lookGenerationError: null,
      hasUnsavedChanges: true,
      configuratorTemplateId: '',
      configuratorSelections: const {},
      configuratorSummary: '',
      selectedWeddingDressId: null,
      weddingCategoryFilter: WeddingCategoryFilter.all,
      weddingFulfillment: WeddingFulfillment.rent,
      rentalDays: 3,
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

  final bool lookGenerating;
  final String? lookGenerationError;

  /// True until [EditorNotifier.saveDesign] succeeds, or after local edits
  /// following a successful save / [loadDesign] baseline.
  final bool hasUnsavedChanges;

  /// Active modular configurator template id (`configurator_templates.id`).
  final String configuratorTemplateId;

  /// Slot id → option id selections for the Build tab.
  final ConfiguratorSelections configuratorSelections;

  /// Human-readable summary for save / quote (Build tab).
  final String configuratorSummary;

  /// Selected catalogue dress on the Wedding tab.
  final String? selectedWeddingDressId;

  final WeddingCategoryFilter weddingCategoryFilter;
  final WeddingFulfillment weddingFulfillment;
  final int rentalDays;

  bool get isWeddingTab => activeTab == EditorTab.wedding;

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
    bool unsetRefinedLook = false,
    bool? lookGenerating,
    String? lookGenerationError,
    bool unsetLookError = false,
    bool? hasUnsavedChanges,
    String? configuratorTemplateId,
    ConfiguratorSelections? configuratorSelections,
    String? configuratorSummary,
    String? selectedWeddingDressId,
    bool unsetSelectedWeddingDressId = false,
    WeddingCategoryFilter? weddingCategoryFilter,
    WeddingFulfillment? weddingFulfillment,
    int? rentalDays,
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
      lookGenerating: lookGenerating ?? this.lookGenerating,
      lookGenerationError: unsetLookError
          ? null
          : (lookGenerationError ?? this.lookGenerationError),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      configuratorTemplateId:
          configuratorTemplateId ?? this.configuratorTemplateId,
      configuratorSelections:
          configuratorSelections ?? this.configuratorSelections,
      configuratorSummary: configuratorSummary ?? this.configuratorSummary,
      selectedWeddingDressId: unsetSelectedWeddingDressId
          ? null
          : (selectedWeddingDressId ?? this.selectedWeddingDressId),
      weddingCategoryFilter:
          weddingCategoryFilter ?? this.weddingCategoryFilter,
      weddingFulfillment: weddingFulfillment ?? this.weddingFulfillment,
      rentalDays: rentalDays ?? this.rentalDays,
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
    state = state.copyWith(mannequinId: id, hasUnsavedChanges: true);
  }

  void setCustomMannequinImagePath(String? path) {
    state = state.copyWith(
      customMannequinImagePath: path,
      hasUnsavedChanges: true,
    );
  }

  void setCatalogDesignPath(String assetPath) {
    final isCasual = isCasualCatalogDesignPath(assetPath);
    state = state.copyWith(
      selectedCatalogDesignPath: assetPath,
      garmentType: isCasual
          ? garmentTypeFromCatalogDesignPath(assetPath)
          : state.garmentType,
      hasUnsavedChanges: true,
    );
    if (isCasual) {
      loadFabrics();
    }
  }

  void setCatalogFilter(DesignCatalogFilter filter) {
    final sections = catalogSectionsFor(filter);
    var path = state.selectedCatalogDesignPath;
    if (sections.isNotEmpty) {
      final visible = sections.expand((e) => e.$2).toSet();
      if (!visible.contains(path)) {
        path = sections.first.$2.first;
      }
    }
    final isCasual = filter == DesignCatalogFilter.casual ||
        isCasualCatalogDesignPath(path);
    state = state.copyWith(
      catalogFilter: filter,
      selectedCatalogDesignPath: path,
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
    state = state.copyWith(primaryColour: colour, hasUnsavedChanges: true);
  }

  void setAccentColour(Color colour) {
    state = state.copyWith(accentColour: colour, hasUnsavedChanges: true);
  }

  void setTool(EditorTool tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setTab(EditorTab tab) {
    var next = tab;
    if (tab == EditorTab.ai && !kFeatureAiEditorTab) {
      next = EditorTab.designs;
    }
    if (tab == EditorTab.wedding && !kFeatureWeddingTab) {
      next = EditorTab.designs;
    }
    state = state.copyWith(activeTab: next);
  }

  void setInitialTab(EditorTab tab) {
    setTab(tab);
  }

  void setWeddingDressId(String? dressId) {
    state = state.copyWith(selectedWeddingDressId: dressId);
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

  /// Applies [kDefaultConfiguratorTemplateId] when build has no valid template.
  void ensureDefaultConfiguratorTemplate(List<ConfiguratorTemplate> templates) {
    if (templates.isEmpty) return;
    final current = state.configuratorTemplateId.trim();
    if (current.isNotEmpty) {
      final stillValid = templates.any((t) => t.id == current);
      if (stillValid && state.configuratorSelections.isNotEmpty) return;
      if (stillValid && state.configuratorSelections.isEmpty) {
        setConfiguratorTemplate(current, templates);
        return;
      }
    }
    final preferred = templates.any(
      (t) => t.id == kDefaultConfiguratorTemplateId,
    )
        ? kDefaultConfiguratorTemplateId
        : templates.first.id;
    setConfiguratorTemplate(preferred, templates);
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
    state = state.copyWith(
      configuratorTemplateId: templateId,
      configuratorSelections: selections,
      configuratorSummary: summary,
      garmentType: template.garmentType,
      hasUnsavedChanges: true,
    );
  }

  /// Clears modular build state (call when leaving the editor).
  void resetConfigurator() {
    state = state.copyWith(
      configuratorTemplateId: '',
      configuratorSelections: const {},
      configuratorSummary: '',
      activeTab: EditorTab.designs,
    );
  }

  /// Resets AI colours and restores default modest abaya slot picks.
  void resetConfiguratorBuild(List<ConfiguratorTemplate> templates) {
    final initial = EditorState.initial();
    state = state.copyWith(
      primaryColour: initial.primaryColour,
      accentColour: initial.accentColour,
      activeTab: EditorTab.build,
      heroMode: EditorHeroMode.compose,
      refinedLookUrl: null,
      lookGenerationError: null,
      hasUnsavedChanges: true,
    );
    if (templates.isEmpty) {
      state = state.copyWith(
        configuratorTemplateId: '',
        configuratorSelections: const {},
        configuratorSummary: '',
      );
      return;
    }
    final preferred = templates.any(
      (t) => t.id == kDefaultConfiguratorTemplateId,
    )
        ? kDefaultConfiguratorTemplateId
        : templates.first.id;
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
    final selections = Map<String, String>.from(state.configuratorSelections);
    selections[slotId] = optionId;
    final summary = configuratorSummaryText(
      template: template,
      selections: selections,
      designName: state.designName,
    );
    state = state.copyWith(
      configuratorSelections: selections,
      configuratorSummary: summary,
      hasUnsavedChanges: true,
    );
  }

  void setFabricQuality(String quality) {
    state = state.copyWith(fabricQuality: quality, hasUnsavedChanges: true);
  }

  void setFabric(String fabricId) {
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
      lookGenerating: false,
      lookGenerationError: null,
      hasUnsavedChanges: false,
      configuratorTemplateId: '',
      configuratorSelections: const {},
      configuratorSummary: '',
      selectedWeddingDressId: initial.selectedWeddingDressId,
      weddingCategoryFilter: initial.weddingCategoryFilter,
      weddingFulfillment: initial.weddingFulfillment,
      rentalDays: initial.rentalDays,
    );
  }

  /// Applies a regional preset (garment + palette + optional fabric/pattern)
  /// to live editor state, then refreshes fabrics for the new garment type.
  void loadPreset(EditorPresetArgs args) {
    final trimmedCatalog = args.catalogDesignPath?.trim() ?? '';
    final catalogOk = trimmedCatalog.isNotEmpty &&
        trimmedCatalog.startsWith('assets/images/designs/');
    final presetId = args.presetId ?? '';
    final garment = args.garmentType ?? '';
    final isCasual = presetId.startsWith('casual_') ||
        kCasualGarmentTypes.contains(garment);
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
      activeTool: EditorTool.colour,
      activeTab: EditorTab.designs,
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
    final configurator = parseConfiguratorFromRenderMetadata(
      design.renderMetadata,
    );
    state = state.copyWith(
      designName: design.name,
      garmentType: snapshot.garmentType,
      primaryColour: _parseHexColor(design.primaryColour),
      accentColour: design.accentColour != null && design.accentColour!.isNotEmpty
          ? _parseHexColor(design.accentColour!)
          : state.accentColour,
      selectedFabricId: design.fabricId ?? state.selectedFabricId,
      fabricQuality: design.fabricQuality ?? state.fabricQuality,
      selectedPatternId: design.patternId ?? state.selectedPatternId,
      printImagePath: design.printImageUrl,
      sketchImagePath: design.sketchImageUrl,
      printPlacement: snapshot.printPlacement,
      printOffsetX: snapshot.printOffsetX,
      printOffsetY: snapshot.printOffsetY,
      printScale: snapshot.printScale,
      textLayers: snapshot.textLayers,
      mannequinId: design.mannequinId ?? state.mannequinId,
      remoteDesignId: design.id,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.designs,
      selectedCatalogDesignPath: snapshot.catalogDesignPath,
      catalogFilter:
          snapshot.isCasual ? DesignCatalogFilter.casual : DesignCatalogFilter.all,
      configuratorTemplateId: configurator.templateId ?? '',
      configuratorSelections: configurator.selections,
      configuratorSummary: configurator.summary ?? '',
      unsetRefinedLook: true,
      heroMode: EditorHeroMode.compose,
      isPrintOverlaySelected: false,
      unsetSelectedTextLayerId: true,
      hasUnsavedChanges: false,
    );
    loadFabrics();
  }

  Future<void> loadFabrics() async {
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.getFabricsForGarmentType(state.garmentType);
    result.fold(
      (_) {},
      (fabrics) {
        if (fabrics.isEmpty) return;
        final fabricIds = fabrics.map((e) => e.id).toList(growable: false);
        final selected = fabricIds.contains(state.selectedFabricId)
            ? state.selectedFabricId
            : fabricIds.first;
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
      activeTab: EditorTab.designs,
      hasUnsavedChanges: true,
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final v = hex.replaceAll('#', '').trim();
      if (v.isEmpty) return state.primaryColour;
      final normalized = v.length == 6 ? 'FF$v' : v.padLeft(8, 'F');
      return Color(int.parse(normalized, radix: 16));
    } on Exception {
      return state.primaryColour;
    }
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
      activeTab: EditorTab.designs,
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

  String _garmentTypeForSave() {
    final path = state.selectedCatalogDesignPath.trim();
    if (isCasualCatalogDesignPath(path) ||
        state.catalogFilter == DesignCatalogFilter.casual) {
      return garmentTypeFromCatalogDesignPath(path);
    }
    return state.garmentType;
  }

  Future<SaveDesignResult> saveDesign({String? forceName}) async {
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
      } on Exception {
        return null;
      }
    }

    String? catalogFlatUrl;
    final catalogPath = state.selectedCatalogDesignPath.trim();
    if (catalogPath.isNotEmpty) {
      final raw = await loadBundle(catalogPath);
      if (raw != null && raw.isNotEmpty) {
        catalogFlatUrl = await uploadBytes(raw, 'catalog-flat.png');
        if (catalogFlatUrl == null) {
          state = state.copyWith(isSaving: false);
          return const SaveDesignResult(
            success: false,
            message: 'Could not upload catalogue design image.',
          );
        }
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
        'aiLookUserPrompt': state.aiLookUserPrompt.trim(),
        'aiLookPromptSuffix': kAiLookPromptSuffix,
        if (editorMannequinUrl != null && editorMannequinUrl.isNotEmpty)
          'editorMannequinImageUrl': editorMannequinUrl,
        if (state.configuratorTemplateId.isNotEmpty)
          kConfiguratorMetadataKey: buildConfiguratorMetadataBlock(
            templateId: state.configuratorTemplateId,
            selections: state.configuratorSelections,
            summary: state.configuratorSummary,
          ),
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

  /// Saves the current design, starts `/ai/design-render`, polls until complete.
  Future<GenerateLookResult> generateRefinedLook() async {
    state = state.copyWith(
      lookGenerating: true,
      unsetLookError: true,
    );
    final saved = await saveDesign();
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

    for (var attempt = 0; attempt < 90; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
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
            if (url != null && url.isNotEmpty) {
              state = state.copyWith(
                lookGenerating: false,
                refinedLookUrl: url,
                heroMode: EditorHeroMode.look,
                unsetLookError: true,
                hasUnsavedChanges: true,
              );
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
    const localFallbackIds = <String>{
      'standard_female',
      'curvy_female',
      'petite_female',
      'athletic_female',
      'plus_female',
      'standard_male',
      'tall_male',
      'child',
      'custom_photo',
    };
    final id = state.mannequinId.trim();
    if (id.isEmpty || localFallbackIds.contains(id)) {
      return null;
    }
    return id;
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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
