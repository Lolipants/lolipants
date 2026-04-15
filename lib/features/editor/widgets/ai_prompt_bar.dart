import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/editor/data/ai_design_service.dart';
import 'package:lolipants/features/editor/models/garment_design_suggestion.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

final aiDesignServiceProvider = Provider<AiDesignService>(
  (ref) => AiDesignService(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Stores latest AI suggestion so users can revisit it.
final aiLastSuggestionProvider = StateProvider<GarmentDesignSuggestion?>(
  (ref) => null,
);

/// AI prompt input + response area for design suggestion.
class AiPromptBar extends ConsumerStatefulWidget {
  /// Creates AI prompt bar widget.
  ///
  /// When [embedInEditor] is true (editor bottom AI tab), "Apply" updates
  /// [editorProvider] live instead of creating a remote draft.
  const AiPromptBar({super.key, this.embedInEditor = false});

  /// Embedded in design editor vs home modal (draft + navigate).
  final bool embedInEditor;

  @override
  ConsumerState<AiPromptBar> createState() => _AiPromptBarState();
}

class _AiPromptBarState extends ConsumerState<AiPromptBar> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  GarmentDesignSuggestion? _suggestion;

  static const _quickPrompts = <String>[
    'Traditional Qatari Thobe with gold trim',
    'Modern black Abaya with silver embroidery',
    'Minimalist white Kandura',
    "Colourful children's Jalabiya",
  ];

  @override
  void initState() {
    super.initState();
    _suggestion = ref.read(aiLastSuggestionProvider);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
          Text('AI · ذكاء اصطناعي', style: AppTextStyles.labelGold),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LolipantsTextField(
                  label: AppStrings.aiPromptLabel,
                  controller: _promptController,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gold,
                child: IconButton(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPrompts
                  .map(
                    (prompt) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ActionChip(
                        label: Text(prompt),
                        onPressed: () => _promptController.text = prompt,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading)
            Row(
              children: const [
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(AppStrings.aiGenerating),
              ],
            )
          else if (_error != null)
            Text(
              AppStrings.aiCreateFailed,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.rubyLight),
            )
          else if (_suggestion != null)
            _SuggestionPreview(
              suggestion: _suggestion!,
              onApply: _applyToDesign,
              onTryAgain: () {
                ref.read(aiLastSuggestionProvider.notifier).state = null;
                setState(() => _suggestion = null);
              },
            ),
        ],
    );

    if (widget.embedInEditor) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: content,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: content,
    );
  }

  Future<void> _submit() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestion = null;
    });
    final garmentType = widget.embedInEditor
        ? ref.read(editorProvider).garmentType
        : 'thobe';
    final service = ref.read(aiDesignServiceProvider);
    final result = await service.generateDesign(
      prompt: prompt,
      garmentType: garmentType,
      currentStyle: 'classic',
    );
    if (!mounted) return;
    result.fold(
      (e) => setState(() {
        _isLoading = false;
        _error = designErrorMessage(e, fallback: 'AI request failed');
      }),
      (suggestion) => setState(() {
        _isLoading = false;
        _suggestion = suggestion;
        ref.read(aiLastSuggestionProvider.notifier).state = suggestion;
      }),
    );
  }

  Future<void> _applyToDesign() async {
    final suggestion = _suggestion;
    if (suggestion == null) return;

    if (widget.embedInEditor) {
      ref.read(editorProvider.notifier).applyAiSuggestion(suggestion);
      ref.read(aiLastSuggestionProvider.notifier).state = null;
      if (!mounted) return;
      setState(() => _suggestion = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.aiAppliedToDesign)),
      );
      return;
    }

    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.createDesign(
      payload: {
        'name': 'AI Draft',
        'garmentType': 'thobe',
        'primaryColour': suggestion.primaryColour,
        'accentColour': suggestion.accentColour,
        'fabricId': suggestion.fabricId,
        'patternId': suggestion.patternId,
      },
    );
    if (!mounted) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            designErrorMessage(
              error,
              fallback: 'Could not apply AI suggestion.',
            ),
          ),
        ),
      ),
      (_) async {
        ref.read(aiLastSuggestionProvider.notifier).state = null;
        await ref.read(myDesignsProvider.notifier).reload();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        if (!context.mounted) return;
        context.go('/profile/designs');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.aiDraftCreated),
          ),
        );
      },
    );
  }
}

class _SuggestionPreview extends StatelessWidget {
  const _SuggestionPreview({
    required this.suggestion,
    required this.onApply,
    required this.onTryAgain,
  });

  final GarmentDesignSuggestion suggestion;
  final VoidCallback onApply;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((suggestion.description ?? '').isNotEmpty)
          Text(suggestion.description!, style: AppTextStyles.bodyMedium),
        if ((suggestion.descriptionAr ?? '').isNotEmpty)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(suggestion.descriptionAr!, style: AppTextStyles.arabicBody),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ColorDot(hex: suggestion.primaryColour),
            if ((suggestion.accentColour ?? '').isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              _ColorDot(hex: suggestion.accentColour!),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: LolipantsButton(
                label: AppStrings.aiApply,
                onPressed: onApply,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onTryAgain,
              child: const Text(AppStrings.aiTryAgain),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final color = _fromHex(hex);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderDefault),
      ),
    );
  }
}

Color _fromHex(String hex) {
  final value = hex.replaceAll('#', '');
  final normalized = value.length == 6 ? 'FF$value' : value.padLeft(8, 'F');
  return Color(int.parse(normalized, radix: 16));
}
