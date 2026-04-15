import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/colour_strip.dart';
import 'package:lolipants/features/editor/widgets/editor_bottom_panel.dart';
import 'package:lolipants/features/editor/widgets/image_print_panel.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/features/editor/widgets/tool_rail.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Phase 3A editor shell screen.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.initialMannequinId});

  final String? initialMannequinId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _seededInitialMannequin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorProvider.notifier).loadFabrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    if (!_seededInitialMannequin && widget.initialMannequinId != null) {
      notifier.setMannequin(widget.initialMannequinId!);
      _seededInitialMannequin = true;
    }

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
                  onPreview: () => context.push('/editor/preview'),
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
                          child: MannequinViewer(
                            garmentType: editor.garmentType,
                            primaryColour: editor.primaryColour,
                            accentColour: editor.accentColour,
                            textLayers: editor.textLayers,
                            selectedTextLayerId: editor.selectedTextLayerId,
                            onSelectTextLayer: notifier.selectTextLayer,
                            onMoveTextLayer: notifier.updateSelectedText,
                            printImagePath: editor.printImagePath,
                            customMannequinImagePath:
                                editor.customMannequinImagePath,
                            printPlacement: editor.printPlacement,
                            printScale: editor.printScale,
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
                scale: editor.printScale,
                onImageSelected: notifier.setPrintImagePath,
                onPlacementChanged: notifier.setPrintPlacement,
                onScaleChanged: notifier.setPrintScale,
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
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.rubyLight),
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
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
    if (name == null || name.trim().isEmpty) return;
    final result = await notifier.saveDesign(forceName: name);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.editorSaved)),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not save design.')),
      );
    }
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.onBack,
    required this.onSave,
    required this.onPreview,
    required this.saving,
  });

  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onPreview;
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
            onPressed: onPreview,
            icon: const Icon(Icons.threed_rotation),
          ),
          SizedBox(
            width: 110,
            child: LolipantsButton(
              label: AppStrings.editorSave,
              onPressed: onSave,
              loading: saving,
              fullWidth: false,
            ),
          ),
        ],
      ),
    );
  }
}
