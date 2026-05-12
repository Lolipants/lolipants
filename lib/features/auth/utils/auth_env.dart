import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lolipants/core/constants/app_strings.dart';

/// When non-null, auth HTTP clients are not configured (`.env` missing URL).
String? missingBetterAuthBaseUrlMessage() {
  final u = dotenv.env['BETTER_AUTH_BASE_URL']?.trim() ?? '';
  if (u.isEmpty) {
    return AppStrings.errorAuthBaseUrlMissing;
  }
  return null;
}

/// When non-null, native Google Sign-In is not configured (`.env` missing ID).
String? missingGoogleServerClientIdMessage() {
  final u = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
  if (u.isEmpty) {
    return AppStrings.errorGoogleServerClientIdMissing;
  }
  return null;
}
