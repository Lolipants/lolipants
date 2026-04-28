import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/auth/data/auth_repository.dart';
import 'package:lolipants/core/router/role_routing.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/auth/utils/auth_env.dart';
import 'package:lolipants/features/auth/utils/auth_error_mapper.dart';

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

  Future<void> _runSocial(SocialProvider provider) async {
    if (_busy) return;
    final envMsg = missingBetterAuthBaseUrlMessage();
    if (envMsg != null) {
      widget.onError?.call(envMsg);
      return;
    }
    setState(() => _busy = true);
    final result =
        await ref.read(authProvider.notifier).signInWithSocial(provider);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (e) {
        final msg = mapAuthExceptionToUserMessage(e);
        widget.onError?.call(msg);
      },
      (user) {
        final returnTo = ref.read(pendingAuthReturnToProvider);
        ref.read(pendingAuthReturnToProvider.notifier).state = null;
        context.go(postAuthLocation(user, returnTo));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          loading: _busy,
          onPressed: () => _runSocial(SocialProvider.google),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SocialButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          loading: _busy,
          onPressed: () => _runSocial(SocialProvider.apple),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SocialButton(
          label: 'Email me a sign-in code',
          icon: Icons.mail_outline,
          loading: false,
          onPressed: _busy ? null : () => context.push('/otp'),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
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
          : Icon(icon, color: AppColors.gold),
      label: Text(label),
    );
  }
}
