import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:lolipants/app.dart';

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

  runApp(const ProviderScope(child: LolipantsApp()));
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
