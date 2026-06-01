import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/editor/data/ai_design_service.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/core/preferences/design_gender_defaults.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/editor/models/garment_design_suggestion.dart';
import 'package:lolipants/features/home/logic/ensure_design_gender.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/editor/utils/ai_colour_parse.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';
import 'package:lolipants/core/l10n/app_localization.dart';

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
  const AiPromptBar({super.key, this.embedInEditor = false, this.initialGender});

  /// Embedded in design editor vs home modal (draft + navigate).
  final bool embedInEditor;

  /// Gender lane resolved before opening the home sheet (`men` / `women` / `kids`).
  final String? initialGender;

  @override
  ConsumerState<AiPromptBar> createState() => _AiPromptBarState();
}

class _AiPromptBarState extends ConsumerState<AiPromptBar> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  GarmentDesignSuggestion? _suggestion;
  String _garmentType = 'abaya';
  String? _designGender;

  List<(String label, String value)> get _garmentTypes {
    final gender = _designGender ?? UserGenderPreference.women;
    return garmentTypesForGender(gender);
  }

  List<String> get _quickPrompts {
    final gender = _designGender ?? UserGenderPreference.women;
    return quickPromptsForGender(gender);
  }

  void _applyGenderDefaults(String gender) {
    _designGender = gender;
    _garmentType = defaultGarmentTypeForGender(gender);
    final allowed = _garmentTypes.map((e) => e.$2).toSet();
    if (!allowed.contains(_garmentType)) {
      _garmentType = _garmentTypes.first.$2;
    }
  }

  @override
  void initState() {
    super.initState();
    _suggestion = ref.read(aiLastSuggestionProvider);
    if (!widget.embedInEditor) {
      final gender = widget.initialGender ?? ref.read(userGenderProvider);
      if (gender != null && UserGenderPreference.all.contains(gender)) {
        _applyGenderDefaults(gender);
      }
    }
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
              children: _garmentTypes
                  .map(
                    (pair) => Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(pair.$1),
                        selected: _garmentType == pair.$2,
                        onSelected: (selected) {
                          if (selected) setState(() => _garmentType = pair.$2);
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPrompts
                  .map(
                    (prompt) => Padding(
                      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
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
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(pickSlashFromContext(context, AppStrings.aiGenerating)),
              ],
            )
          else if (_error != null)
            Text(
              _error!,
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
      child: SingleChildScrollView(
        child: content,
      ),
    );
  }

  Future<void> _submit() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    if (widget.embedInEditor) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final notifier = ref.read(editorProvider.notifier);
      notifier.setAiLookUserPrompt(prompt);
      final result = await notifier.generateRefinedLook();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!result.success && result.message != null) {
          _error = result.message;
        }
      });
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Look generated. Check preview above.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _suggestion = null;
    });

    if (!widget.embedInEditor) {
      final gender = _designGender ??
          widget.initialGender ??
          ref.read(userGenderProvider);
      final resolved = gender != null &&
              UserGenderPreference.all.contains(gender)
          ? gender
          : await ensureDesignGender(context, ref);
      if (!mounted) return;
      if (resolved == null) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _applyGenderDefaults(resolved));
    }

    final garmentType = _garmentType;
    final service = ref.read(aiDesignServiceProvider);
    final result = await service.generateDesign(
      prompt: prompt,
      garmentType: garmentType,
      currentStyle: 'classic',
      gender: _designGender,
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
        SnackBar(
          content: Text(
            pickSlashFromContext(context, AppStrings.aiAppliedToDesign),
          ),
        ),
      );
      return;
    }

    final gender = _designGender ??
        widget.initialGender ??
        ref.read(userGenderProvider);
    final resolved = gender != null && UserGenderPreference.all.contains(gender)
        ? gender
        : await ensureDesignGender(context, ref);
    if (!mounted || resolved == null) return;
    _applyGenderDefaults(resolved);

    final mannequinId = mannequinIdForGender(resolved);
    final prompt = _promptController.text.trim();
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.createDesign(
      payload: {
        'name': 'AI Draft',
        'garmentType': _garmentType,
        'mannequinId': canonicalMannequinIdForApi(mannequinId) ?? mannequinId,
        'primaryColour': suggestion.primaryColour,
        'accentColour': suggestion.accentColour,
        'fabricId': suggestion.fabricId,
        'patternId': suggestion.patternId,
        'renderMetadata': {
          'editorMannequinId': mannequinId,
          'garmentType': _garmentType,
          'primaryColour': suggestion.primaryColour,
          'accentColour': suggestion.accentColour,
          'fabricId': suggestion.fabricId,
          'patternId': suggestion.patternId,
          'aiLookUserPrompt': prompt,
          'buildStyleMode': 'configurator',
          'aiHomeDraft': true,
          if ((suggestion.description ?? '').trim().isNotEmpty)
            'aiSuggestionDescription': suggestion.description!.trim(),
        },
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
      (design) async {
        ref.read(aiLastSuggestionProvider.notifier).state = null;
        await ref.read(myDesignsProvider.notifier).reload();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        if (!context.mounted) return;
        context.go('/editor', extra: design);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pickSlashFromContext(context, AppStrings.aiDraftCreated),
            ),
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
              child: Text(pickSlashFromContext(context, AppStrings.aiTryAgain)),
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
    final color = parseAiColour(hex);
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
