import 'package:flutter/material.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/features/editor/models/design_text_layer.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/models/garment_design_suggestion.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';

export 'package:lolipants/features/editor/models/design_text_layer.dart';

/// Editor interaction tools shown in the side rail.
enum EditorTool { colour, text, image, sizing }

/// Bottom panel tabs for the editor shell.
enum EditorTab { fabric, pattern, embroidery, text, ai }

/// Image print placement presets.
enum PrintPlacement { chest, back, fullFront }

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
    required this.printImagePath,
    required this.customMannequinImagePath,
    required this.printPlacement,
    required this.printOffsetX,
    required this.printOffsetY,
    required this.printScale,
    required this.isSaving,
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
      activeTab: EditorTab.fabric,
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
      printImagePath: null,
      customMannequinImagePath: null,
      printPlacement: PrintPlacement.chest,
      printOffsetX: 0,
      printOffsetY: 0,
      printScale: 40,
      isSaving: false,
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
  final String? printImagePath;
  final String? customMannequinImagePath;
  final PrintPlacement printPlacement;
  final double printOffsetX;
  final double printOffsetY;
  final double printScale;
  final bool isSaving;

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
    String? printImagePath,
    String? customMannequinImagePath,
    PrintPlacement? printPlacement,
    double? printOffsetX,
    double? printOffsetY,
    double? printScale,
    bool? isSaving,
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
      selectedTextLayerId: selectedTextLayerId ?? this.selectedTextLayerId,
      printImagePath: printImagePath ?? this.printImagePath,
      customMannequinImagePath:
          customMannequinImagePath ?? this.customMannequinImagePath,
      printPlacement: printPlacement ?? this.printPlacement,
      printOffsetX: printOffsetX ?? this.printOffsetX,
      printOffsetY: printOffsetY ?? this.printOffsetY,
      printScale: printScale ?? this.printScale,
      isSaving: isSaving ?? this.isSaving,
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
    state = state.copyWith(designName: value);
  }

  void setMannequin(String id) {
    state = state.copyWith(mannequinId: id);
  }

  void setCustomMannequinImagePath(String? path) {
    state = state.copyWith(customMannequinImagePath: path);
  }

  void setPrimaryColour(Color colour) {
    state = state.copyWith(primaryColour: colour);
  }

  void setAccentColour(Color colour) {
    state = state.copyWith(accentColour: colour);
  }

  void setTool(EditorTool tool) {
    state = state.copyWith(activeTool: tool);
    if (tool == EditorTool.colour) {
      state = state.copyWith(activeTab: EditorTab.fabric);
    }
  }

  void setTab(EditorTab tab) {
    var next = tab;
    if (tab == EditorTab.ai && !kFeatureAiEditorTab) {
      next = EditorTab.fabric;
    }
    state = state.copyWith(activeTab: next);
  }

  void setFabricQuality(String quality) {
    state = state.copyWith(fabricQuality: quality);
  }

  void setFabric(String fabricId) {
    state = state.copyWith(selectedFabricId: fabricId);
  }

  /// Applies a regional preset (garment + palette + optional fabric/pattern)
  /// to live editor state, then refreshes fabrics for the new garment type.
  void loadPreset(EditorPresetArgs args) {
    state = state.copyWith(
      designName: args.designName ?? state.designName,
      garmentType: args.garmentType ?? state.garmentType,
      primaryColour: args.primaryColour ?? state.primaryColour,
      accentColour: args.accentColour ?? state.accentColour,
      selectedFabricId: args.fabricId ?? state.selectedFabricId,
      selectedPatternId: args.patternId ?? state.selectedPatternId,
      mannequinId: args.mannequinId ?? state.mannequinId,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.fabric,
    );
    loadFabrics();
  }

  /// Hydrates editor state from a previously saved [GarmentDesign] so the
  /// user can edit it again.
  void loadDesign(GarmentDesign design) {
    state = state.copyWith(
      designName: design.name,
      garmentType: design.garmentType,
      primaryColour: _parseHexColor(design.primaryColour),
      accentColour: design.accentColour != null && design.accentColour!.isNotEmpty
          ? _parseHexColor(design.accentColour!)
          : state.accentColour,
      selectedFabricId: design.fabricId ?? state.selectedFabricId,
      fabricQuality: design.fabricQuality ?? state.fabricQuality,
      selectedPatternId: design.patternId ?? state.selectedPatternId,
      printImagePath: design.printImageUrl,
      mannequinId: design.mannequinId ?? state.mannequinId,
      activeTool: EditorTool.colour,
      activeTab: EditorTab.fabric,
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
    state = state.copyWith(selectedPatternId: patternId);
  }

  void setEmbroidery(String embroideryId) {
    state = state.copyWith(selectedEmbroideryId: embroideryId);
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
      activeTab: EditorTab.fabric,
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
      activeTool: EditorTool.text,
      activeTab: EditorTab.text,
    );
  }

  void selectTextLayer(String id) {
    state = state.copyWith(selectedTextLayerId: id);
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
    final updated = <DesignTextLayer>[];
    for (final layer in state.textLayers) {
      if (layer.id == selectedId) {
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
    state = state.copyWith(textLayers: updated);
  }

  void removeSelectedText() {
    final selectedId = state.selectedTextLayerId;
    if (selectedId == null) return;
    state = state.copyWith(
      textLayers: state.textLayers.where((l) => l.id != selectedId).toList(),
      selectedTextLayerId: null,
    );
  }

  void setPrintImagePath(String? path) {
    state = state.copyWith(printImagePath: path, activeTool: EditorTool.image);
  }

  void setPrintPlacement(PrintPlacement placement) {
    state = state.copyWith(printPlacement: placement);
  }

  void setPrintOffsetX(double value) {
    state = state.copyWith(printOffsetX: value);
  }

  void setPrintOffsetY(double value) {
    state = state.copyWith(printOffsetY: value);
  }

  void setPrintScale(double value) {
    state = state.copyWith(printScale: value);
  }

  Future<SaveDesignResult> saveDesign({String? forceName}) async {
    final repo = ref.read(designsRepositoryProvider);
    final name = (forceName ?? state.designName).trim();
    if (name.isEmpty) {
      return const SaveDesignResult(
        success: false,
        message: 'Design name is required.',
      );
    }
    state = state.copyWith(isSaving: true, designName: name);
    String? printImageUrl = state.printImagePath;
    if (printImageUrl != null &&
        printImageUrl.isNotEmpty &&
        !printImageUrl.startsWith('http')) {
      final upload = await repo.uploadPrintImage(filePath: printImageUrl);
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
      printImageUrl = uploaded;
      state = state.copyWith(printImagePath: uploaded);
    }

    final payload = <String, dynamic>{
      'name': name,
      'garmentType': state.garmentType,
      'primaryColour': _colorToHex(state.primaryColour),
      'accentColour': _colorToHex(state.accentColour),
      'fabricId': state.selectedFabricId,
      'fabricQuality': state.fabricQuality,
      'patternId': state.selectedPatternId,
      'printImageUrl': printImageUrl,
      'printPlacement': state.printPlacement.name,
      'printOffsetX': state.printOffsetX,
      'printOffsetY': state.printOffsetY,
      'printScale': state.printScale,
      'mannequinId': _normalizedMannequinIdForApi(),
      'customMannequinImagePath': state.customMannequinImagePath,
      'renderMetadata': {
        'mannequinTemplateId': _resolveMannequinTemplateId(),
        'garmentType': state.garmentType,
        'primaryColour': _colorToHex(state.primaryColour),
        'accentColour': _colorToHex(state.accentColour),
        'fabricProfile': state.fabricQuality,
        'printImageUrl': printImageUrl,
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
    final result = await repo.createDesign(payload: payload);
    state = state.copyWith(isSaving: false);
    return result.fold(
      (e) => SaveDesignResult(
        success: false,
        message: designErrorMessage(e, fallback: 'Could not save design.'),
      ),
      (design) {
        ref.read(myDesignsProvider.notifier).reload();
        return SaveDesignResult(
          success: true,
          designId: design.id,
        );
      },
    );
  }

  String? _normalizedMannequinIdForApi() {
    const localFallbackIds = <String>{
      'standard_female',
      'curvy_female',
      'petite_female',
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
    if (garment == 'abaya' || id.contains('female')) return 'female_abaya_v1';
    if (garment == 'bisht') return 'unisex_bisht_v1';
    if (id.contains('male')) return 'male_thobe_v1';
    return 'default_thobe_v1';
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(ref),
);
