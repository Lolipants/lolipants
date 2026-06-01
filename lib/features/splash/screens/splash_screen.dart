import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/splash/widgets/mascot_animation.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/locale_bilingual_text.dart';

/// Branded splash with session routing.
class SplashScreen extends ConsumerStatefulWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _prefsKey = 'has_seen_onboarding';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeAfterBoot());
  }

  Future<void> _routeAfterBoot() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 2500)),
      ref.read(authProvider.future).catchError((Object _, StackTrace __) {
        return const AuthUnauthenticated();
      }),
    ]);
    if (!mounted) {
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeen = prefs.getBool(_prefsKey) ?? false;
    final auth = ref.read(authProvider).value;
    if (auth is AuthAuthenticated) {
      context.go(homeForRole(auth.user));
    } else if (!hasSeen) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(42);
    final stars = List.generate(11, (_) {
      final left = rnd.nextDouble();
      final top = rnd.nextDouble();
      final size = 1.5 + rnd.nextDouble();
      final opacity = 0.2 + rnd.nextDouble() * 0.3;
      return Positioned(
        left: left * MediaQuery.sizeOf(context).width,
        top: top * MediaQuery.sizeOf(context).height,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sand.withValues(alpha: opacity),
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          const ArabesqueBackground(opacity: 0.04),
          ...stars,
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotAnimation()
                    .animate()
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: AppSpacing.lg),
                LocaleBilingualText(
                  en: AppStrings.appName,
                  ar: AppStrings.appNameAr,
                  enStyle: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 0.15,
                  ),
                  arStyle: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 0.15,
                  ),
                )
                    .animate()
                    .slideY(begin: 0.3, duration: 500.ms, delay: 400.ms)
                    .fadeIn(duration: 500.ms, delay: 400.ms),
                Text(
                  AppStrings.brandLatin,
                  style: AppTextStyles.labelGold.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.22,
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 700.ms),
                const SizedBox(height: AppSpacing.md),
                const GoldDivider(width: 32)
                    .animate()
                    .scaleX(
                      begin: 0,
                      duration: 300.ms,
                      delay: 900.ms,
                      alignment: Alignment.center,
                    ),
                const SizedBox(height: AppSpacing.md),
                LocaleBilingualText(
                  en: AppStrings.tagline,
                  ar: AppStrings.taglineAr,
                  enStyle: AppTextStyles.bodySmall,
                  arStyle: AppTextStyles.arabicBody.copyWith(fontSize: 11),
                ).animate().fadeIn(duration: 300.ms, delay: 1100.ms),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: _DotLoader(),
          ),
        ],
      ),
    );
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) {
        setState(() => _i = (_i + 1) % 3);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == _i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: active ? 1 : 0.22),
            borderRadius: BorderRadius.circular(100),
          ),
        );
      }),
    );
  }
}
