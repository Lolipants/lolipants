import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Three-slide onboarding flow (Phase 2).
class OnboardingScreen extends StatelessWidget {
  /// Creates the onboarding screen.
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.onboardingDesignTitle)),
    );
  }
}
