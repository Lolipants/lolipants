import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/core/utils/validators.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';
import 'package:lolipants/features/auth/widgets/social_auth_row.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/gold_divider.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Registration screen.
class SignupScreen extends ConsumerStatefulWidget {
  /// Creates the sign-up screen.
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _banner;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    final nameKey = Validators.nameErrorKey(_name.text);
    final emailKey = Validators.emailErrorKey(_email.text);
    final pwKey = Validators.passwordSignupErrorKey(_password.text);
    setState(() {
      _nameError = switch (nameKey) {
        'name_short' => AppStrings.errorNameShort,
        'required' => AppStrings.errorRequired,
        _ => null,
      };
      _emailError = switch (emailKey) {
        'required' => AppStrings.errorRequired,
        'invalid_email' => AppStrings.errorInvalidEmail,
        _ => null,
      };
      _passwordError = switch (pwKey) {
        'required' => AppStrings.errorRequired,
        'password_short' => AppStrings.errorPasswordShort,
        'password_no_digit' => AppStrings.errorPasswordDigit,
        _ => null,
      };
      _confirmError = _password.text != _confirm.text
          ? AppStrings.errorPasswordMismatch
          : null;
    });
    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    setState(() => _banner = null);
    if (!_validate()) {
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(authProvider.notifier).signUpWithProfile(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    result.fold(
      (e) => setState(() => _banner = mapAuthExceptionToUserMessage(e)),
      (user) {
        final returnTo = ref.read(pendingAuthReturnToProvider);
        ref.read(pendingAuthReturnToProvider.notifier).state = null;
        context.go(postAuthLocation(user, returnTo));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                  Text(
                    AppStrings.createAccount,
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      AppStrings.createAccountAr,
                      style: AppTextStyles.arabicLabel,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const GoldDivider(width: 40),
                  const SizedBox(height: AppSpacing.xl),
                  if (_banner != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ErrorBanner(
                        message: _banner!,
                        onDismiss: () => setState(() => _banner = null),
                      ),
                    ),
                  LolipantsTextField(
                    label: AppStrings.fullName,
                    controller: _name,
                    errorText: _nameError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.email,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.password,
                    controller: _password,
                    obscureText: true,
                    obscureToggle: true,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsTextField(
                    label: AppStrings.confirmPassword,
                    controller: _confirm,
                    obscureText: true,
                    obscureToggle: true,
                    errorText: _confirmError,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  LolipantsButton(
                    label: AppStrings.createAccountCta,
                    onPressed: _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'or',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.fog,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.borderSubtle),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SocialAuthRow(
                    onError: (msg) => setState(() => _banner = msg),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/login'),
                        child: Text(
                          '${AppStrings.logIn} / ${AppStrings.logInAr}',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LoadingOverlay(visible: _loading),
        ],
      ),
    );
  }
}
