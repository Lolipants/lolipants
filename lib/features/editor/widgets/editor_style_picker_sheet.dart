import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/full_spectrum_color_picker.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Opens the editor colour bottom sheet.
Future<void> showEditorStylePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.52,
      minChildSize: 0.38,
      maxChildSize: 0.82,
      builder: (_, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
            border: Border(
              top: BorderSide(color: AppColors.borderStrong),
            ),
          ),
          child: EditorStylePickerSheet(scrollController: scrollController),
        );
      },
    ),
  );
}

/// Colour picker content for the palette FAB sheet.
class EditorStylePickerSheet extends ConsumerWidget {
  const EditorStylePickerSheet({required this.scrollController, super.key});

  final ScrollController scrollController;

  static const _presetColours = <Color>[
    Color(0xFF162F28),
    AppColors.gold,
    Color(0xFF1A1040),
    Color(0xFF6B1A1A),
    AppColors.sand,
    AppColors.ink,
    Color(0xFF2C1810),
    Color(0xFF4A5568),
  ];

  static const _qualityOptionIds = <String>[
    'standard',
    'premium',
    'suit_grade',
  ];

  static String _qualityLabel(Locale locale, String id) {
    return switch (id) {
      'premium' => localizedFromLocale(
          locale,
          AppStrings.editorQualityPremium,
          AppStrings.editorQualityPremiumAr,
        ),
      'suit_grade' => localizedFromLocale(
          locale,
          AppStrings.editorQualitySuitGrade,
          AppStrings.editorQualitySuitGradeAr,
        ),
      _ => localizedFromLocale(
          locale,
          AppStrings.editorQualityStandard,
          AppStrings.editorQualityStandardAr,
        ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final primaryColourTitle = localizedFromLocale(
      locale,
      AppStrings.editorBuildColorPrimary,
      AppStrings.editorBuildColorPrimaryAr,
    );

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        const _SheetDragHandle(),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            children: [
              Text(
                localizedFromLocale(
                  locale,
                  AppStrings.editorStyleYourPiece,
                  AppStrings.editorStyleYourPieceAr,
                ),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.sand,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                localizedFromLocale(
                  locale,
                  AppStrings.editorStyleColourHint,
                  AppStrings.editorStyleColourHintAr,
                ),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionCard(
                icon: Icons.palette_outlined,
                title: primaryColourTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SelectedColourPreview(
                          locale: locale,
                          colour: editor.primaryColour,
                          onCustomTap: () => _pickCustomColour(
                            context,
                            locale,
                            editor.primaryColour,
                            notifier.setPrimaryColour,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ColourSwatchGrid(
                            colours: _presetColours,
                            selected: editor.primaryColour,
                            onSelected: notifier.setPrimaryColour,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => _pickCustomColour(
                        context,
                        locale,
                        editor.primaryColour,
                        notifier.setPrimaryColour,
                      ),
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(
                        localizedFromLocale(
                          locale,
                          AppStrings.editorMoreColours,
                          AppStrings.editorMoreColoursAr,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                icon: Icons.grade_outlined,
                title: localizedFromLocale(
                  locale,
                  AppStrings.editorQualityTier,
                  AppStrings.editorQualityTierAr,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SegmentedButton<String>(
                      segments: [
                        for (final id in _qualityOptionIds)
                          ButtonSegment<String>(
                            value: id,
                            label: Text(
                              _qualityLabel(locale, id),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                      style: SegmentedButton.styleFrom(
                        backgroundColor: AppColors.smoke,
                        foregroundColor: AppColors.dust,
                        selectedForegroundColor: AppColors.sand,
                        selectedBackgroundColor:
                            AppColors.gold.withValues(alpha: 0.22),
                        side: const BorderSide(
                          color: AppColors.borderSubtle,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      selected: {editor.fabricQuality},
                      onSelectionChanged: (next) {
                        if (next.isEmpty) return;
                        notifier.setFabricQuality(next.first);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
          ),
          child: LolipantsButton(
            label: localizedFromLocale(
              locale,
              AppStrings.editorDone,
              AppStrings.editorDoneAr,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCustomColour(
    BuildContext context,
    Locale locale,
    Color current,
    ValueChanged<Color> onSelected,
  ) async {
    final picked = await showFullSpectrumColorPicker(
      context,
      initialColor: current,
      title: localizedFromLocale(
        locale,
        AppStrings.editorCustomColour,
        AppStrings.editorCustomColourAr,
      ),
    );
    if (picked != null) onSelected(picked);
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderDefault,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ember.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.gold),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.sand,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectedColourPreview extends StatelessWidget {
  const _SelectedColourPreview({
    required this.locale,
    required this.colour,
    required this.onCustomTap,
  });

  final Locale locale;
  final Color colour;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onCustomTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colour,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          localizedFromLocale(
            locale,
            AppStrings.editorTapToFineTune,
            AppStrings.editorTapToFineTuneAr,
          ),
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 9,
            color: AppColors.fog,
          ),
        ),
      ],
    );
  }
}

class _ColourSwatchGrid extends StatelessWidget {
  const _ColourSwatchGrid({
    required this.colours,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colours;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final c in colours)
          _ColourDot(
            colour: c,
            selected: c.toARGB32() == selected.toARGB32(),
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _ColourDot extends StatelessWidget {
  const _ColourDot({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colour,
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderDefault,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: colour.computeLuminance() > 0.55
                      ? AppColors.ink
                      : Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}
