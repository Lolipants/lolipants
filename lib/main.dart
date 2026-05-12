import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:lolipants/app.dart';
import 'package:lolipants/core/preferences/shared_preferences_provider.dart';
import 'package:lolipants/core/push/onesignal_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application entrypoint: loads env, logging, and starts Flutter.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _configureLogging();

  try {
    await dotenv.load();
  } on Exception catch (e, stackTrace) {
    Logger('lolipants.bootstrap').warning(
      'Could not load .env; using empty defaults.',
      e,
      stackTrace,
    );
    dotenv.testLoad(
      fileInput: '''
BETTER_AUTH_BASE_URL=
CLOUDFLARE_API_BASE=
API_BASE_URL=
CLOUDFLARE_R2_BASE_URL=
''',
    );
  }

  final googleServer = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim() ?? '';
  if (googleServer.isNotEmpty) {
    try {
      await GoogleSignIn.instance.initialize(serverClientId: googleServer);
    } on Exception catch (e, st) {
      Logger('lolipants.bootstrap').warning(
        'GoogleSignIn.initialize failed; Google sign-in may not work.',
        e,
        st,
      );
    }
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LolipantsApp(),
    ),
  );

  // Initialise OneSignal after `runApp` so the first frame isn't blocked by
  // the plugin's network handshake. Failures log and no-op.
  unawaited(initOneSignal());
}

void _configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });
}
