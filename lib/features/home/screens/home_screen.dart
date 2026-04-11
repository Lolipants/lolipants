import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/home/widgets/style_card.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/arabic_english_label.dart';
import 'package:lolipants/shared/widgets/bottom_nav_bar.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Phase 1 preview: design tokens, shared widgets, and bottom navigation.
class HomeScreen extends StatefulWidget {
  /// Creates the home / foundation preview screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  bool _loading = false;
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _simulateLoading() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              child: _HomePreviewBody(
                emailController: _emailController,
                onSimulateLoading: _simulateLoading,
              ),
            ),
          ),
          LoadingOverlay(visible: _loading),
        ],
      ),
      bottomNavigationBar: LolipantsBottomNavBar(
        currentIndex: _tabIndex,
        onChanged: (index) => setState(() => _tabIndex = index),
      ),
    );
  }
}

class _HomePreviewBody extends StatelessWidget {
  const _HomePreviewBody({
    required this.emailController,
    required this.onSimulateLoading,
  });

  final TextEditingController emailController;
  final VoidCallback onSimulateLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.designFoundationTitle,
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            AppStrings.designFoundationTitleAr,
            style: AppTextStyles.arabicBody.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.designFoundationSubtitle,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            AppStrings.designFoundationSubtitleAr,
            style: AppTextStyles.arabicBody.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const GoldDivider(width: 120),
        const SizedBox(height: AppSpacing.xl),
        ArabicEnglishLabel(
          arabicText: AppStrings.welcomeBackAr,
          englishText: AppStrings.welcomeBack.toUpperCase(),
        ),
        const SizedBox(height: AppSpacing.xl),
        LolipantsTextField(
          label: AppStrings.email,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.lg),
        const LolipantsTextField(
          label: AppStrings.password,
          obscureText: true,
          obscureToggle: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        LolipantsButton(
          label: '${AppStrings.tryPrimary} / ${AppStrings.tryPrimaryAr}',
          onPressed: onSimulateLoading,
        ),
        const SizedBox(height: AppSpacing.md),
        LolipantsButton(
          label: '${AppStrings.trySecondary} / ${AppStrings.trySecondaryAr}',
          variant: LolipantsButtonVariant.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        LolipantsButton(
          label: '${AppStrings.tryDestructive} / ${AppStrings.tryDestructiveAr}',
          variant: LolipantsButtonVariant.destructive,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          AppStrings.sectionTraditionalStyles,
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.92,
          children: const [
            StyleCard.qatariThobe(),
            StyleCard.saudiBisht(),
            StyleCard.uaeKandura(),
            StyleCard.omaniDishdasha(),
          ],
        ),
      ],
    );
  }
}
