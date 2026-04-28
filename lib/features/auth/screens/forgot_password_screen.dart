import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/utils/validators.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Password reset request screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Creates the forgot-password screen.
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;
  String? _banner;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = Validators.emailErrorKey(_email.text);
    setState(() {
      _banner = null;
      _emailError = switch (key) {
        'required' => AppStrings.errorRequired,
        'invalid_email' => AppStrings.errorInvalidEmail,
        _ => null,
      };
    });
    if (_emailError != null) {
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.forgotPassword(_email.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    result.fold(
      (e) => setState(() => _banner = mapAuthExceptionToUserMessage(e)),
      (_) => setState(() => _sent = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _sent
                  ? _Success(email: _email.text.trim())
                  : _Form(
                      email: _email,
                      emailError: _emailError,
                      banner: _banner,
                      onDismissBanner: () => setState(() => _banner = null),
                      onSubmit: _submit,
                    ),
            ),
          ),
          LoadingOverlay(visible: _loading),
        ],
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.email,
    required this.emailError,
    required this.banner,
    required this.onDismissBanner,
    required this.onSubmit,
  });

  final TextEditingController email;
  final String? emailError;
  final String? banner;
  final VoidCallback onDismissBanner;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          AppStrings.resetPasswordTitle,
          style: AppTextStyles.titleLarge,
        ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            AppStrings.resetPasswordTitleAr,
            style: AppTextStyles.arabicLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (banner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ErrorBanner(
              message: banner!,
              onDismiss: onDismissBanner,
            ),
          ),
        LolipantsTextField(
          label: AppStrings.email,
          controller: email,
          keyboardType: TextInputType.emailAddress,
          errorText: emailError,
        ),
        const SizedBox(height: AppSpacing.xl),
        LolipantsButton(
          label: '${AppStrings.sendResetLink} / ${AppStrings.sendResetLinkAr}',
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_unread_outlined,
            size: 48, color: AppColors.gold),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${AppStrings.checkYourInbox} / ${AppStrings.checkYourInboxAr}',
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${AppStrings.resetEmailSentPrefix}$email',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        LolipantsButton(
          label: '${AppStrings.backToLogIn} / ${AppStrings.backToLogInAr}',
          variant: LolipantsButtonVariant.secondary,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
