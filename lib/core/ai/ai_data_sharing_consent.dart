import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// SharedPreferences key for third-party AI data-sharing consent.
const String kAiDataSharingConsentKey = 'lolipants_ai_data_sharing_consent';

/// Gate for features that send user data to Google Gemini and/or OpenAI.
abstract final class AiDataSharingConsent {
  /// Whether the user has agreed to third-party AI data sharing.
  static bool isGranted(WidgetRef ref) {
    return ref.read(sharedPreferencesProvider).getBool(kAiDataSharingConsentKey) ??
        false;
  }

  /// Clears stored consent so the disclosure dialog appears again.
  static Future<void> revoke(WidgetRef ref) async {
    await ref.read(sharedPreferencesProvider).remove(kAiDataSharingConsentKey);
  }

  static Future<void> _grant(WidgetRef ref) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(kAiDataSharingConsentKey, true);
  }

  /// Shows the disclosure dialog when needed. Returns true only after consent.
  static Future<bool> ensure(BuildContext context, WidgetRef ref) async {
    if (isGranted(ref)) return true;
    if (!context.mounted) return false;

    final locale = ref.read(settingsLocaleProvider);
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          localizedFromLocale(
            locale,
            AppStrings.aiConsentTitle,
            AppStrings.aiConsentTitleAr,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            localizedFromLocale(
              locale,
              AppStrings.aiConsentMessage,
              AppStrings.aiConsentMessageAr,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              localizedFromLocale(
                locale,
                AppStrings.aiConsentDecline,
                AppStrings.aiConsentDeclineAr,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              localizedFromLocale(
                locale,
                AppStrings.aiConsentAgree,
                AppStrings.aiConsentAgreeAr,
              ),
            ),
          ),
        ],
      ),
    );

    if (agreed == true) {
      await _grant(ref);
      return true;
    }
    return false;
  }
}
