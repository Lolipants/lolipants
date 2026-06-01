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
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/shared/widgets/locale_bilingual_text.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Email/password login.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates the login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _banner;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final emailKey = Validators.emailErrorKey(_email.text);
    setState(() {
      _banner = null;
      final locale = Localizations.localeOf(context);
      _emailError = switch (emailKey) {
        'required' => AppStrings.localized(
          locale,
          AppStrings.errorRequired,
          AppStrings.errorRequiredAr,
        ),
        'invalid_email' => AppStrings.localized(
          locale,
          AppStrings.errorInvalidEmail,
          AppStrings.errorInvalidEmailAr,
        ),
        _ => null,
      };
      _passwordError = _password.text.isEmpty
          ? AppStrings.localized(
              locale,
              AppStrings.errorRequired,
              AppStrings.errorRequiredAr,
            )
          : null;
    });
    if (_emailError != null || _passwordError != null) {
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(authProvider.notifier).signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    result.fold(
      (e) => setState(
            () => _banner = mapAuthExceptionToUserMessage(
              e,
              locale: Localizations.localeOf(context),
            ),
          ),
      (user) {
        final returnTo = ref.read(pendingAuthReturnToProvider);
        ref.read(pendingAuthReturnToProvider.notifier).state = null;
        context.go(postAuthLocation(user, returnTo));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recoveryMessage = ref.watch(authRecoveryMessageProvider);
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
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                  LocaleBilingualText(
                    en: AppStrings.welcomeBack,
                    ar: AppStrings.welcomeBackAr,
                    enStyle: AppTextStyles.titleLarge,
                    arStyle: AppTextStyles.arabicLabel,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const GoldDivider(width: 40),
                  const SizedBox(height: AppSpacing.xl),
                  if (recoveryMessage != null || _banner != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ErrorBanner(
                        message: recoveryMessage ?? _banner!,
                        onDismiss: () {
                          ref.read(authRecoveryMessageProvider.notifier).state =
                              null;
                          setState(() => _banner = null);
                        },
                      ),
                    ),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot'),
                      child: Text(
                        localizedFromContext(
                          context,
                          AppStrings.forgotPassword,
                          AppStrings.forgotPasswordAr,
                        ),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.gold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsButton(
                    label: localizedFromContext(
                      context,
                      AppStrings.logInCta,
                      AppStrings.logInCtaAr,
                    ),
                    onPressed: _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.lg),
                  SocialAuthRow(
                    onError: (msg) => setState(() => _banner = msg),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.dontHaveAccount,
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: Text(
                          localizedFromContext(context, AppStrings.signUp, AppStrings.signUpAr),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderSubtle)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'or',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderSubtle)),
      ],
    );
  }
}
