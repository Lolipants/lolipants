import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/core/utils/validators.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Two-step passwordless sign-in: request an email OTP, then enter the
/// 6-digit code to receive a session.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

enum _OtpStep { enterEmail, enterCode }

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  _OtpStep _step = _OtpStep.enterEmail;
  String? _banner;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final emailKey = Validators.emailErrorKey(_email.text);
    if (emailKey != null) {
      setState(() => _banner = 'Enter a valid email.');
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() {
      _loading = true;
      _banner = null;
    });
    final result =
        await ref.read(authProvider.notifier).sendEmailOtp(_email.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (e) => setState(
            () => _banner = mapAuthExceptionToUserMessage(
              e,
              locale: Localizations.localeOf(context),
            ),
          ),
      (_) => setState(() => _step = _OtpStep.enterCode),
    );
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().length != 6) {
      setState(() => _banner = 'Enter the 6-digit code.');
      return;
    }
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      setState(() => _banner = envMsg);
      return;
    }
    setState(() {
      _loading = true;
      _banner = null;
    });
    final result = await ref.read(authProvider.notifier).verifyEmailOtp(
          email: _email.text.trim(),
          otp: _code.text.trim(),
        );
    if (!mounted) return;
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
                        onPressed: () {
                          if (_step == _OtpStep.enterCode) {
                            setState(() => _step = _OtpStep.enterEmail);
                          } else {
                            context.pop();
                          }
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                    ],
                  ),
                  Text(
                    _step == _OtpStep.enterEmail
                        ? 'Sign in with email'
                        : 'Enter your code',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _step == _OtpStep.enterEmail
                        ? 'We will email a 6-digit sign-in code to this address.'
                        : 'We emailed a code to ${_email.text.trim()}. It expires in 10 minutes.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_banner != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ErrorBanner(
                        message: _banner!,
                        onDismiss: () => setState(() => _banner = null),
                      ),
                    ),
                  if (_step == _OtpStep.enterEmail)
                    LolipantsTextField(
                      label: 'Email',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    )
                  else
                    LolipantsTextField(
                      label: '6-digit code',
                      controller: _code,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  LolipantsButton(
                    label: _step == _OtpStep.enterEmail
                        ? 'Send code'
                        : 'Verify and sign in',
                    loading: _loading,
                    onPressed:
                        _step == _OtpStep.enterEmail ? _sendCode : _verifyCode,
                  ),
                  if (_step == _OtpStep.enterCode) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: _loading ? null : _sendCode,
                      child: const Text(
                        'Resend code',
                        style: TextStyle(color: AppColors.gold),
                      ),
                    ),
                  ],
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
