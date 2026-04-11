import 'package:flutter/material.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// Email/password login (Phase 2).
class LoginScreen extends StatelessWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text(AppStrings.logIn)),
    );
  }
}
