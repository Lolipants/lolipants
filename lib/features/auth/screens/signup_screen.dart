import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Registration screen (Phase 2).
class SignupScreen extends StatelessWidget {
  /// Creates the sign-up screen.
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.createAccount)),
    );
  }
}
