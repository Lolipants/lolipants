import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
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
    super.key,
  });

  final Future<void> Function() onGenerate;

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

    return Material(
      color: AppColors.stone,
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.editorStudioPromptTitle,
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.sand),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.editorStudioPromptSubtitle,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
            ),
            const SizedBox(height: AppSpacing.sm),
            LolipantsTextField(
              label: AppStrings.aiPromptLabel,
              controller: _controller,
              onChanged: notifier.setAiLookUserPrompt,
            ),
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.xs,
                        ),
                        child: ActionChip(
                          label: Text(
                            p,
                            style: AppTextStyles.bodySmall,
                          ),
                          onPressed: editor.lookGenerating
                              ? null
                              : () {
                                  _controller.text = p;
                                  notifier.setAiLookUserPrompt(p);
                                },
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
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
