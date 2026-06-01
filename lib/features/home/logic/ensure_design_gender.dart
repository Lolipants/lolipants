import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:lolipants/features/home/widgets/design_gender_dialog.dart';

bool _hasValidGender(String? gender) =>
    gender != null && UserGenderPreference.all.contains(gender);

/// Prompts for gender after sign-in using the root navigator.
///
/// The login screen is disposed when auth state flips and GoRouter redirects,
/// so a [BuildContext] from [SocialAuthRow] is not reliable here.
Future<void> promptGenderAfterAuth(Ref ref) async {
  if (_hasValidGender(ref.read(userGenderProvider))) {
    return;
  }

  Future<void> tryShow({required int attempt}) async {
    if (_hasValidGender(ref.read(userGenderProvider))) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      if (attempt < 8) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => tryShow(attempt: attempt + 1),
        );
      }
      return;
    }
    final picked = await showDesignGenderDialog(ctx);
    if (picked != null) {
      await ref.read(userGenderProvider.notifier).persistGender(picked);
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => tryShow(attempt: 0));
}

/// Loads gender from API/local storage; prompts when still unset.
///
/// Returns null when the user dismisses the picker without choosing.
Future<String?> ensureDesignGender(
  BuildContext context,
  WidgetRef ref,
) async {
  final notifier = ref.read(userGenderProvider.notifier);
  await notifier.syncFromApi();

  final current = ref.read(userGenderProvider);
  if (_hasValidGender(current)) {
    return current;
  }

  if (!context.mounted) return null;
  final picked = await showDesignGenderDialog(context);
  if (picked == null) return null;

  await notifier.persistGender(picked);
  return picked;
}
