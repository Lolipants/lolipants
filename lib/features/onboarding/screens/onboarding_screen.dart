import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Three-slide onboarding flow.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  const _Slide({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.imageAsset,
  });

  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String imageAsset;
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _prefsKey = 'has_seen_onboarding';
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      titleEn: 'Design your fashion',
      titleAr: 'صمم أزياءك',
      bodyEn: AppStrings.onboardingSlide1Body,
      imageAsset: 'assets/images/onboarding_screen1.jpg',
    ),
    _Slide(
      titleEn: 'Rooted in heritage',
      titleAr: 'مستوحى من تراثك',
      bodyEn: AppStrings.onboardingSlide2Body,
      imageAsset: 'assets/images/onboarding_screen2.jpg',
    ),
    _Slide(
      titleEn: 'Made by master tailors',
      titleAr: 'مصنوع بأيدي محترفين',
      bodyEn: AppStrings.onboardingSlide3Body,
      imageAsset: 'assets/images/onboarding_screen3.jpg',
    ),
  ];

  Future<void> _finishToSignup() async {
    await ref.read(sharedPreferencesProvider).setBool(_prefsKey, true);
    if (mounted) {
      context.go('/signup');
    }
  }

  Future<void> _skipToLogin() async {
    await ref.read(sharedPreferencesProvider).setBool(_prefsKey, true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              children: [
                if (_page < 2)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _skipToLogin,
                      child: Text('${AppStrings.skip} / ${AppStrings.skipAr}'),
                    ),
                  )
                else
                  const SizedBox(height: 48),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, index) {
                      final s = _slides[index];
                      return Column(
                        children: [
                          Expanded(
                            flex: 55,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                AppSpacing.md,
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                child: ColoredBox(
                                  color: AppColors.ink,
                                  child: Image.asset(
                                    s.imageAsset,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 30,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: AppColors.stone,
                                // borderRadius: BorderRadius.vertical(
                                //   top: Radius.circular(AppRadius.xl),
                                // ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      s.titleAr,
                                      style: AppTextStyles.displayMedium
                                          .copyWith(color: AppColors.gold),
                                    ),
                                  ),
                                  Text(s.titleEn, style: AppTextStyles.titleLarge),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(s.bodyEn, style: AppTextStyles.bodyMedium),
                                  const SizedBox(height: AppSpacing.xxl),
                                  if (index == 2)
                                    LolipantsButton(
                                      label:
                                          '${AppStrings.getStarted} / ${AppStrings.getStartedAr}',
                                      onPressed: _finishToSignup,
                                    ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(_slides.length, (i) {
                                      final on = i == _page;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width: on ? 24 : 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withValues(
                                            alpha: on ? 1 : 0.25,
                                          ),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      );
                                    }),
                                  ),
                                  
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
