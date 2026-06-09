import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/widgets/featured_design_carousel.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';
import 'package:lolipants/features/home/widgets/home_flow_choice_button.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Guided home flow: one centered step at a time with transitions.
class HomeDesignFlow extends ConsumerWidget {
  const HomeDesignFlow({super.key});

  static const double _maxButtonWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final selection = ref.watch(homeFlowSelectionProvider);
    final notifier = ref.read(homeFlowSelectionProvider.notifier);
    final step = activeStepFor(selection);
    final isAr = locale.languageCode == 'ar';
    final buttonWidth = MediaQuery.sizeOf(context).width - 48;
    final choiceWidth =
        buttonWidth > _maxButtonWidth ? _maxButtonWidth : buttonWidth;

    VoidCallback? onBack;
    switch (step) {
      case HomeFlowStep.gender:
        onBack = null;
      case HomeFlowStep.style:
        onBack = notifier.clearFromStyle;
      case HomeFlowStep.service:
      case HomeFlowStep.confirm:
        onBack = notifier.clearServiceType;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: onBack != null
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.fog,
                    ),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                )
              : null,
        ),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: _StepPanel(
                key: ValueKey<HomeFlowStep>(step),
                step: step,
                locale: locale,
                isAr: isAr,
                selection: selection,
                choiceWidth: choiceWidth,
                onGender: notifier.setGender,
                onStyle: notifier.setStyle,
                onService: notifier.setServiceType,
                onStart: () => openHomeDesignFlow(context, selection),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    required this.step,
    required this.locale,
    required this.isAr,
    required this.selection,
    required this.choiceWidth,
    required this.onGender,
    required this.onStyle,
    required this.onService,
    required this.onStart,
    super.key,
  });

  final HomeFlowStep step;
  final Locale locale;
  final bool isAr;
  final HomeFlowSelection selection;
  final double choiceWidth;
  final Future<void> Function(String gender) onGender;
  final void Function(HomeStyleLane style) onStyle;
  final void Function(HomeServiceType serviceType) onService;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StepHeader(
            title: _titleForStep(step),
            isAr: isAr,
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._choicesForStep(),
        ],
      ),
    );
  }

  String _titleForStep(HomeFlowStep step) {
    return switch (step) {
      HomeFlowStep.gender => localizedFromLocale(
          locale,
          AppStrings.homeFlowStepGender,
          AppStrings.homeFlowStepGenderAr,
        ),
      HomeFlowStep.style => localizedFromLocale(
          locale,
          AppStrings.homeFlowStepStyle,
          AppStrings.homeFlowStepStyleAr,
        ),
      HomeFlowStep.service => localizedFromLocale(
          locale,
          AppStrings.homeFlowStepService,
          AppStrings.homeFlowStepServiceAr,
        ),
      HomeFlowStep.confirm => localizedFromLocale(
          locale,
          AppStrings.homeFlowStartDesigning,
          AppStrings.homeFlowStartDesigningAr,
        ),
    };
  }

  List<Widget> _choicesForStep() {
    return switch (step) {
      HomeFlowStep.gender => [
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.man_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeCategoryMen,
              AppStrings.homeCategoryMenAr,
            ),
            onTap: () => onGender(UserGenderPreference.men),
          ),
          const SizedBox(height: AppSpacing.md),
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.woman_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeCategoryWomen,
              AppStrings.homeCategoryWomenAr,
            ),
            onTap: () => onGender(UserGenderPreference.women),
          ),
        ],
      HomeFlowStep.style => [
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.public_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeTraditionalTitle,
              AppStrings.homeTraditionalTitleAr,
            ),
            onTap: () => onStyle(HomeStyleLane.traditional),
          ),
          const SizedBox(height: AppSpacing.md),
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.auto_awesome_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeFlowStyleModern,
              AppStrings.homeFlowStyleModernAr,
            ),
            onTap: () => onStyle(HomeStyleLane.modern),
          ),
          if (selection.showWeddingStyle) ...[
            const SizedBox(height: AppSpacing.md),
            HomeFlowChoiceButton(
              buttonWidth: choiceWidth,
              isAr: isAr,
              icon: Icons.favorite_border,
              label: localizedFromLocale(
                locale,
                AppStrings.homeFlowStyleWedding,
                AppStrings.homeFlowStyleWeddingAr,
              ),
              onTap: () => onStyle(HomeStyleLane.wedding),
            ),
          ],
        ],
      HomeFlowStep.service => [
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.palette_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeFlowDesignYourself,
              AppStrings.homeFlowDesignYourselfAr,
            ),
            subtitle: localizedFromLocale(
              locale,
              AppStrings.homeFlowDesignYourselfBody,
              AppStrings.homeFlowDesignYourselfBodyAr,
            ),
            onTap: () => onService(HomeServiceType.designYourself),
          ),
          const SizedBox(height: AppSpacing.md),
          HomeFlowChoiceButton(
            buttonWidth: choiceWidth,
            isAr: isAr,
            icon: Icons.checkroom_outlined,
            label: localizedFromLocale(
              locale,
              AppStrings.homeFlowFinishProduct,
              AppStrings.homeFlowFinishProductAr,
            ),
            subtitle: localizedFromLocale(
              locale,
              AppStrings.homeFlowFinishProductBody,
              AppStrings.homeFlowFinishProductBodyAr,
            ),
            onTap: () => onService(HomeServiceType.finishProduct),
          ),
        ],
      HomeFlowStep.confirm => [
          Text(
            localizedFromLocale(
              locale,
              AppStrings.homeFlowMeasurementsNote,
              AppStrings.homeFlowMeasurementsNoteAr,
            ),
            style: (isAr ? AppTextStyles.arabicBody : AppTextStyles.bodySmall)
                .copyWith(color: AppColors.fog, fontSize: 12),
            textAlign: TextAlign.center,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: choiceWidth,
            child: LolipantsButton(
              label: localizedFromLocale(
                locale,
                AppStrings.homeFlowStartDesigning,
                AppStrings.homeFlowStartDesigningAr,
              ),
              fullWidth: true,
              onPressed: onStart,
            ),
          ),
        ],
    };
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.isAr});

  final String title;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      textAlign: TextAlign.center,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}
