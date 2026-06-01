import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Row of social login / email-OTP buttons shown above the email/password
/// form on both the login and signup screens.
///
/// Handles the in-flight state, success redirect, and error surfacing so the
/// host screen only has to embed the widget.
class SocialAuthRow extends ConsumerStatefulWidget {
  const SocialAuthRow({super.key, this.onError});

  /// Optional callback so the host screen can render an inline banner when
  /// a provider fails. Called with a user-facing message.
  final ValueChanged<String>? onError;

  @override
  ConsumerState<SocialAuthRow> createState() => _SocialAuthRowState();
}

class _SocialAuthRowState extends ConsumerState<SocialAuthRow> {
  bool _busy = false;
  bool _appleAvailable = false;

  /// Synchronous guard: two taps before the first [setState] can both pass
  /// `if (_busy)` and start two sign-in attempts.
  bool _googleFlowEntered = false;
  bool _appleFlowEntered = false;

  @override
  void initState() {
    super.initState();
    _probeAppleAvailability();
  }

  Future<void> _probeAppleAvailability() async {
    if (kIsWeb) {
      return;
    }
    if (!Platform.isIOS && !Platform.isMacOS) {
      return;
    }
    final available = await SignInWithApple.isAvailable();
    if (!mounted) {
      return;
    }
    setState(() => _appleAvailable = available);
  }

  Future<void> _runApple() async {
    if (_busy || _appleFlowEntered) return;
    _appleFlowEntered = true;
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      _appleFlowEntered = false;
      widget.onError?.call(envMsg);
      return;
    }
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(authProvider.notifier).signInWithApple();
      if (!mounted) return;
      result.fold(
        (e) {
          if (e is AuthException && e.message == 'oauth_in_progress') {
            return;
          }
          final msg = mapAuthExceptionToUserMessage(
            e,
            locale: Localizations.localeOf(context),
          );
          widget.onError?.call(msg);
        },
        (user) {
          final returnTo = ref.read(pendingAuthReturnToProvider);
          ref.read(pendingAuthReturnToProvider.notifier).state = null;
          context.go(postAuthLocation(user, returnTo));
        },
      );
    } finally {
      _appleFlowEntered = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runGoogle() async {
    if (_busy || _googleFlowEntered) return;
    _googleFlowEntered = true;
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      _googleFlowEntered = false;
      widget.onError?.call(envMsg);
      return;
    }
    final googleMsg = missingGoogleServerClientIdMessage();
    if (googleMsg != null) {
      _googleFlowEntered = false;
      widget.onError?.call(googleMsg);
      return;
    }
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(authProvider.notifier).signInWithGoogle();
      result.fold(
        (e) {
          if (!mounted) return;
          if (e is AuthException && e.message == 'oauth_in_progress') {
            return;
          }
          final msg = mapAuthExceptionToUserMessage(
            e,
            locale: Localizations.localeOf(context),
          );
          widget.onError?.call(msg);
        },
        (user) {
          // Gender prompt runs from [_afterAuthenticated] via root navigator
          // (this widget is often disposed before we get here).
          if (!mounted) return;
          final returnTo = ref.read(pendingAuthReturnToProvider);
          ref.read(pendingAuthReturnToProvider.notifier).state = null;
          context.go(postAuthLocation(user, returnTo));
        },
      );
    } finally {
      _googleFlowEntered = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_appleAvailable) ...[
          SignInWithAppleButton(
            onPressed: _busy ? () {} : _runApple,
            style: SignInWithAppleButtonStyle.white,
            height: 52,
            borderRadius: BorderRadius.circular(14),
            text: 'Continue with Apple',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _SocialButton(
          label: 'Continue with Google',
          leading: _googleBrandIcon(),
          loading: _busy,
          onPressed: _runGoogle,
        ),
        const SizedBox(height: AppSpacing.sm),
        _SocialButton(
          label: 'Email me a sign-in code',
          leading: Icon(Icons.mail_outline, color: AppColors.gold, size: 24),
          loading: false,
          onPressed: _busy ? null : () => context.push('/otp'),
        ),
      ],
    );
  }

  /// Google "G" on white circle — reads on dark outlined buttons even if the
  /// PNG has an opaque square background.
  static Widget _googleBrandIcon() {
    return SizedBox(
      width: 24,
      height: 24,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Image.asset(
            'assets/google/google_logo.png',
            fit: BoxFit.contain,
            semanticLabel: 'Google',
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final Widget leading;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: AppColors.borderDefault),
        foregroundColor: AppColors.sand,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : leading,
      label: Text(label),
    );
  }
}
