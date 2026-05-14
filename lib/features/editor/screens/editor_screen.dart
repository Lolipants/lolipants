import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/screens/create_post_screen.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_bottom_panel.dart';
import 'package:lolipants/features/editor/widgets/editor_studio_prompt_card.dart';
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
  final GlobalKey _heroCaptureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(editorProvider.notifier);
      final initialMannequin =
          widget.bootstrap?.mannequinId ?? widget.initialMannequinId;
      if (!_seededInitialMannequin && initialMannequin != null) {
        notifier.setMannequin(initialMannequin);
        _seededInitialMannequin = true;
      }
      final customPath = widget.bootstrap?.customMannequinImagePath;
      if (customPath != null && customPath.trim().isNotEmpty) {
        notifier.setCustomMannequinImagePath(customPath.trim());
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
                  onShare: () => _shareToCommunity(context),
                  onSizing: () => context.push('/sizing'),
                  saving: editor.isSaving,
                  heroMode: editor.heroMode,
                  onHeroModeChanged: notifier.setHeroMode,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.smoke.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: AppColors.borderSubtle
                                    .withValues(alpha: 0.65),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      key: _heroCaptureKey,
                                      child: ColoredBox(
                                        color: Colors.white,
                                        child: editor.heroMode ==
                                                EditorHeroMode.compose
                                            ? InteractiveViewer(
                                                minScale: 0.85,
                                                maxScale: 3,
                                                child: Center(
                                                  child: Image.asset(
                                                    editor.selectedCatalogDesignPath
                                                            .trim()
                                                            .isEmpty
                                                        ? kDefaultCatalogDesignPath
                                                        : editor
                                                            .selectedCatalogDesignPath,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (_, __, ___) => Center(
                                                      child: Text(
                                                        'Design asset missing',
                                                        style: AppTextStyles
                                                            .bodySmall,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : editor.refinedLookUrl !=
                                                        null &&
                                                    editor.refinedLookUrl!
                                                        .isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: editor
                                                        .refinedLookUrl!,
                                                    fit: BoxFit.contain,
                                                    placeholder: (_, __) =>
                                                        const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  )
                                                : Center(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        AppSpacing.lg,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .checkroom_outlined,
                                                            size: 48,
                                                            color: AppColors
                                                                .fog,
                                                          ),
                                                          const SizedBox(
                                                            height:
                                                                AppSpacing.sm,
                                                          ),
                                                          Text(
                                                            AppStrings
                                                                .editorHeroAiOutputEmpty,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: AppTextStyles
                                                                .bodyMedium
                                                                .copyWith(
                                                              color: AppColors
                                                                  .fog,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
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
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  if (editor.heroMode == EditorHeroMode.look &&
                                      editor.refinedLookUrl != null &&
                                      editor.refinedLookUrl!.isNotEmpty)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton.filledTonal(
                                        tooltip:
                                            AppStrings.editorGenerateLook,
                                        onPressed: editor.lookGenerating
                                            ? null
                                            : () => _generateLook(context),
                                        icon: const Icon(Icons.refresh),
                                      ),
                                    ),
                                  if (editor.heroMode == EditorHeroMode.look &&
                                      editor.refinedLookUrl != null &&
                                      editor.refinedLookUrl!.isNotEmpty)
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
                                            padding: const EdgeInsets.fromLTRB(
                                              AppSpacing.md,
                                              AppSpacing.lg,
                                              AppSpacing.md,
                                              AppSpacing.sm,
                                            ),
                                            child: Text(
                                              AppStrings.editorLookDisclaimer,
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: AppColors.sand
                                                    .withValues(alpha: 0.92),
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
                      EditorStudioPromptCard(
                        key: ValueKey<Object>(
                          '${editor.remoteDesignId ?? 'new'}|${editor.selectedCatalogDesignPath}',
                        ),
                        onGenerate: () => _generateLook(context),
                      ),
                    ],
                  ),
                ),
                EditorBottomPanel(
                  state: editor,
                  onCatalogDesignSelected: notifier.setCatalogDesignPath,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateLook(BuildContext context) async {
    final notifier = ref.read(editorProvider.notifier);
    final result = await notifier.generateRefinedLook();
    if (!context.mounted) return;
    if (!result.success &&
        result.message != null &&
        result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  Future<void> _confirmExit(BuildContext context) async {
    final editor = ref.read(editorProvider);
    if (!editor.hasUnsavedChanges) {
      if (mounted) context.pop();
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
    } else if (result.message != null && result.message!.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
  }

  Future<void> _orderNow(BuildContext context) async {
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
    return notifier.saveDesign(forceName: name.trim());
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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
  });

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onOrder;
  final VoidCallback onShare;
  final VoidCallback onSizing;
  final bool saving;
  final EditorHeroMode heroMode;
  final ValueChanged<EditorHeroMode> onHeroModeChanged;

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
            label: narrow ? null : const Text(AppStrings.editorHeroCompose),
          ),
          ButtonSegment<EditorHeroMode>(
            value: EditorHeroMode.look,
            tooltip: AppStrings.editorHeroAiLook,
            icon: const Icon(Icons.checkroom_outlined, size: 20),
            label: narrow ? null : const Text(AppStrings.editorHeroAiLook),
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
                    onSave();
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
            width: narrow ? 96 : 110,
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
