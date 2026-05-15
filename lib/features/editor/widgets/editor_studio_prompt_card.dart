import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/data/casual_garment_ai_prompts.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Prompt + generate for the AI studio (flat design → on-model render).
///
/// Use a [ValueKey] on this widget when the loaded design identity changes so
/// the text field re-seeds from [EditorState.aiLookUserPrompt].
class EditorStudioPromptCard extends ConsumerStatefulWidget {
  const EditorStudioPromptCard({
    required this.onGenerate,
    this.compact = false,
    super.key,
  });

  final Future<void> Function() onGenerate;

  /// Tighter layout so the hero preview can use more vertical space.
  final bool compact;

  @override
  ConsumerState<EditorStudioPromptCard> createState() =>
      _EditorStudioPromptCardState();
}

class _EditorStudioPromptCardState extends ConsumerState<EditorStudioPromptCard> {
  late final TextEditingController _controller;

  static const _quickPrompts = <String>[
    'Gold trim at cuffs and neckline',
    'Softer drape, floor-length hem',
    'Richer embroidery, traditional feel',
    'Minimal, modern silhouette',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(editorProvider).aiLookUserPrompt,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kFeatureAiEditorTab) return const SizedBox.shrink();

    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    final dense = widget.compact;
    final chipLabelStyle = AppTextStyles.bodySmall.copyWith(
      fontSize: dense ? 11 : null,
    );
    final showCasualGarmentPrompts =
        editor.catalogFilter == DesignCatalogFilter.casual ||
            editor.catalogFilter == DesignCatalogFilter.modern ||
            kCasualGarmentTypes.contains(editor.garmentType);

    return Material(
      color: AppColors.stone,
      elevation: dense ? 2 : 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          dense ? 6 : AppSpacing.sm,
          AppSpacing.md,
          dense ? 8 : AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.editorStudioPromptTitle,
              style: dense
                  ? AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.sand,
                      fontWeight: FontWeight.w600,
                    )
                  : AppTextStyles.titleSmall.copyWith(color: AppColors.sand),
            ),
            SizedBox(height: dense ? 2 : 4),
            Text(
              AppStrings.editorStudioPromptSubtitle,
              maxLines: dense ? 1 : 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.fog,
                fontSize: dense ? 11 : null,
              ),
            ),
            SizedBox(height: dense ? 6 : AppSpacing.sm),
            LolipantsTextField(
              label: AppStrings.aiPromptLabel,
              controller: _controller,
              onChanged: notifier.setAiLookUserPrompt,
            ),
            SizedBox(height: dense ? 6 : AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in _quickPrompts)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: dense ? 4 : AppSpacing.xs,
                      ),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.symmetric(
                          horizontal: dense ? 6 : 8,
                          vertical: dense ? 0 : 2,
                        ),
                        label: Text(p, style: chipLabelStyle),
                        onPressed: editor.lookGenerating
                            ? null
                            : () {
                                _controller.text = p;
                                notifier.setAiLookUserPrompt(p);
                              },
                      ),
                    ),
                  if (showCasualGarmentPrompts)
                    for (final pair in kCasualGarmentAiPromptPairs)
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: dense ? 4 : AppSpacing.xs,
                        ),
                        child: ActionChip(
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(
                            horizontal: dense ? 6 : 8,
                            vertical: dense ? 0 : 2,
                          ),
                          label: Text(
                            pair.$1,
                            style: chipLabelStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: editor.lookGenerating
                              ? null
                              : () {
                                  _controller.text = pair.$2;
                                  notifier.setAiLookUserPrompt(pair.$2);
                                },
                        ),
                      ),
                ],
              ),
            ),
            SizedBox(height: dense ? 6 : AppSpacing.sm),
            if (dense)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  onPressed:
                      editor.lookGenerating ? null : () => widget.onGenerate(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: editor.lookGenerating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ink,
                          ),
                        )
                      : Text(
                          AppStrings.editorGenerateLook,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                ),
              )
            else
              LolipantsButton(
                label: AppStrings.editorGenerateLook,
                onPressed: editor.lookGenerating ? null : widget.onGenerate,
                loading: editor.lookGenerating,
                fullWidth: true,
              ),
          ],
        ),
      ),
    );
  }
}
