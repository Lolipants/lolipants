import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Branded splash with session routing (Phase 2).
class SplashScreen extends StatelessWidget {
  /// Creates the splash screen.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.appName)),
    );
  }
}
