import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Password reset request screen (Phase 2).
class ForgotPasswordScreen extends StatelessWidget {
  /// Creates the forgot-password screen.
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.forgotPassword)),
    );
  }
}
