import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/screens/create_post_screen.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/colour_strip.dart';
import 'package:lolipants/features/editor/widgets/editor_bottom_panel.dart';
import 'package:lolipants/features/editor/widgets/image_print_panel.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/features/editor/widgets/tool_rail.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

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
  bool _seededInitialMannequin = false;
  bool _seededPreset = false;
  bool _sharing = false;
  final GlobalKey _mannequinKey = GlobalKey();

  static const Map<String, ({double x, double y, double minScale, double maxScale})>
      _printLimitsByGarment = {
    'abaya': (x: 85, y: 110, minScale: 22, maxScale: 88),
    'thobe': (x: 72, y: 95, minScale: 20, maxScale: 82),
    'kandura': (x: 70, y: 90, minScale: 20, maxScale: 80),
    'bisht': (x: 90, y: 120, minScale: 24, maxScale: 92),
    'suit': (x: 62, y: 80, minScale: 18, maxScale: 72),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(editorProvider.notifier);
      final initialMannequin = widget.bootstrap?.mannequinId ?? widget.initialMannequinId;
      if (!_seededInitialMannequin && initialMannequin != null) {
        notifier.setMannequin(initialMannequin);
        _seededInitialMannequin = true;
      }
      if (!_seededPreset) {
        if (widget.design != null) {
          notifier.loadDesign(widget.design!);
        } else if (widget.bootstrap?.preset != null) {
          notifier.loadPreset(widget.bootstrap!.preset!);
        } else if (widget.preset != null) {
          notifier.loadPreset(widget.preset!);
        }
        _seededPreset = true;
      }
      notifier.loadFabrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final limits = _printLimitsByGarment[editor.garmentType.toLowerCase()] ??
        (x: 60.0, y: 80.0, minScale: 20.0, maxScale: 80.0);

    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              children: [
                _EditorTopBar(
                  onBack: () => _confirmExit(context),
                  onSave: () => _saveDesign(context),
                  onOrder: () => _orderNow(context),
                  onPreview: kFeatureFinalRenderPreview
                      ? () => context.push('/editor/preview')
                      : null,
                  onShare: () => _shareToCommunity(context),
                  saving: editor.isSaving,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            56,
                            AppSpacing.md,
                            56,
                            AppSpacing.md,
                          ),
                          child: RepaintBoundary(
                            key: _mannequinKey,
                            child: MannequinViewer(
                            garmentType: editor.garmentType,
                            primaryColour: editor.primaryColour,
                            accentColour: editor.accentColour,
                            fabricProfile: editor.fabricQuality,
                            textLayers: editor.textLayers,
                            selectedTextLayerId: editor.selectedTextLayerId,
                            onSelectTextLayer: notifier.selectTextLayer,
                            onMoveTextLayer: notifier.updateSelectedText,
                            printImagePath: editor.printImagePath,
                            customMannequinImagePath:
                                editor.customMannequinImagePath,
                            printPlacement: editor.printPlacement,
                            printOffsetX: editor.printOffsetX,
                            printOffsetY: editor.printOffsetY,
                            printScale: editor.printScale,
                            onMovePrintImage: (delta) {
                              final nextX = (editor.printOffsetX + delta.dx)
                                  .clamp(-limits.x, limits.x)
                                  .toDouble();
                              final nextY = (editor.printOffsetY + delta.dy)
                                  .clamp(-limits.y, limits.y)
                                  .toDouble();
                              notifier.setPrintOffsetX(nextX);
                              notifier.setPrintOffsetY(nextY);
                            },
                          ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.sm,
                        top: 80,
                        child: ToolRail(
                          activeTool: editor.activeTool,
                          onToolSelected: notifier.setTool,
                          onSizingTap: () => context.push('/sizing'),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.sm,
                        top: 80,
                        child: ColourStrip(
                          selectedColour: editor.primaryColour,
                          onSelected: notifier.setPrimaryColour,
                        ),
                      ),
                    ],
                  ),
                ),
                EditorBottomPanel(
                  state: editor,
                  onTabChanged: notifier.setTab,
                  onFabricSelected: notifier.setFabric,
                  onQualitySelected: notifier.setFabricQuality,
                  onPatternSelected: notifier.setPattern,
                  onEmbroiderySelected: notifier.setEmbroidery,
                  onAddTextLayer: notifier.addTextLayer,
                  onSelectTextLayer: notifier.selectTextLayer,
                  onUpdateSelectedText: notifier.updateSelectedText,
                  onRemoveSelectedText: notifier.removeSelectedText,
                ),
              ],
            ),
          ),
          if (editor.activeTool == EditorTool.image)
            Positioned(
              left: 0,
              right: 0,
              bottom: 280,
              child: ImagePrintPanel(
                imagePath: editor.printImagePath,
                placement: editor.printPlacement,
                offsetX: editor.printOffsetX,
                offsetY: editor.printOffsetY,
                scale: editor.printScale,
                onImageSelected: notifier.setPrintImagePath,
                onPlacementChanged: notifier.setPrintPlacement,
                onOffsetXChanged: notifier.setPrintOffsetX,
                onOffsetYChanged: notifier.setPrintOffsetY,
                onScaleChanged: notifier.setPrintScale,
                offsetXRange: limits.x,
                offsetYRange: limits.y,
                minScale: limits.minScale,
                maxScale: limits.maxScale,
                onApply: () => notifier.setTool(EditorTool.colour),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
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
    if (leave == true && context.mounted) {
      context.pop();
    }
  }

  Future<void> _saveDesign(BuildContext context) async {
    final result = await _persistCurrentDesign(context);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editorSaved)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not save design.')),
      );
    }
  }

  Future<void> _orderNow(BuildContext context) async {
    final result = await _persistCurrentDesign(context);
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not save design.')),
      );
      return;
    }
    final editor = ref.read(editorProvider);
    context.push(
      '/order/summary',
      extra: OrderDesignDraft(
        designId: result.designId,
        name: editor.designName.trim().isEmpty
            ? 'Current design'
            : editor.designName,
        garmentType: editor.garmentType,
        primaryColour: _toHex(editor.primaryColour),
        accentColour: _toHex(editor.accentColour),
        fabricId: editor.selectedFabricId,
        patternId: editor.selectedPatternId,
        mannequinId: editor.mannequinId,
      ),
    );
  }

  Future<SaveDesignResult> _persistCurrentDesign(BuildContext context) async {
    final notifier = ref.read(editorProvider.notifier);
    final existingName = ref.read(editorProvider).designName;
    String? name = existingName;
    if (existingName.trim().isEmpty) {
      final controller = TextEditingController();
      name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.stone,
          title: Text('Design name', style: AppTextStyles.titleMedium),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
    if (name == null || name.trim().isEmpty) {
      return const SaveDesignResult(success: false, message: 'Design name is required.');
    }
    return notifier.saveDesign(forceName: name);
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> _shareToCommunity(BuildContext context) async {
    if (_sharing) return;
    _sharing = true;
    try {
      final bytes = await _captureMannequinPng(pixelRatio: 3.2);
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not capture design preview.')),
        );
        return;
      }
      final editor = ref.read(editorProvider);
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
      await context.push('/community/new-post', extra: prefill);
    } finally {
      if (mounted) _sharing = false;
    }
  }

  Future<Uint8List?> _captureMannequinPng({double pixelRatio = 2.5}) async {
    try {
      final context = _mannequinKey.currentContext;
      if (context == null) return null;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } on Object {
      return null;
    }
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.onBack,
    required this.onSave,
    required this.onOrder,
    required this.onPreview,
    required this.onShare,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onOrder;
  final VoidCallback? onPreview;
  final VoidCallback onShare;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              AppStrings.editorTitle,
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            tooltip: 'Share to community',
            onPressed: onShare,
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            onPressed: onPreview,
            icon: const Icon(Icons.threed_rotation),
          ),
          IconButton(
            onPressed: onSave,
            icon: const Icon(Icons.save_outlined),
          ),
          SizedBox(
            width: 110,
            child: LolipantsButton(
              label: 'Order / اطلب',
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
