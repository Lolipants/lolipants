import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:lolipants/core/router/app_router.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

final _log = Logger('lolipants.onesignal');

/// Returns true when `ONESIGNAL_APP_ID` is set so the native SDK was
/// initialised in [initOneSignal].
bool isOneSignalAppConfigured() {
  final appId = dotenv.env['ONESIGNAL_APP_ID']?.trim();
  return appId != null && appId.isNotEmpty;
}

/// Initialises the OneSignal SDK. Safe to call once per app run; subsequent
/// calls are no-ops. Uses the `ONESIGNAL_APP_ID` from `.env` — when the env
/// var is absent we log and skip (push simply stays off).
Future<void> initOneSignal() async {
  final appId = dotenv.env['ONESIGNAL_APP_ID']?.trim();
  if (appId == null || appId.isEmpty) {
    _log.info('ONESIGNAL_APP_ID not set; skipping OneSignal init.');
    return;
  }
  try {
    await OneSignal.Debug.setLogLevel(
      kDebugMode ? OSLogLevel.warn : OSLogLevel.error,
    );
    await OneSignal.initialize(appId);

    // Deep link open handler — push payloads can include a
    // `{ "route": "/orders/<id>" }` additionalData entry that we forward to
    // the go_router root navigator.
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      final route = data?['route'];
      if (route is String && route.isNotEmpty) {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          GoRouter.of(context).push(route);
        }
      }
    });
  } on Object catch (err, stack) {
    _log.warning('OneSignal initialisation failed', err, stack);
  }
}

/// Subscribes or unsubscribes this device on OneSignal (no-op if not configured).
Future<void> setOneSignalPushOptIn({required bool want}) async {
  if (!isOneSignalAppConfigured()) return;
  try {
    if (want) {
      await OneSignal.User.pushSubscription.optIn();
    } else {
      await OneSignal.User.pushSubscription.optOut();
    }
  } on Object catch (err, stack) {
    _log.warning('OneSignal opt-in/out failed', err, stack);
  }
}

/// Requests the OS push permission prompt. Pass the result back to the
/// caller (true = granted). In debug mode we return `true` without
/// prompting so automated flows don't stall.
Future<bool> requestPushPermission() async {
  if (kDebugMode) {
    return true;
  }
  try {
    return await OneSignal.Notifications.requestPermission(true);
  } on Object catch (err, stack) {
    _log.warning('OneSignal permission prompt failed', err, stack);
    return false;
  }
}

/// Returns the current OneSignal `onesignal_id` (subscriber id) for the
/// device, or null if we aren't subscribed yet. Used by the client after
/// opt-in to POST the id to `/users/push-token`.
Future<String?> currentPlayerId() async {
  try {
    return OneSignal.User.pushSubscription.id;
  } on Object {
    return null;
  }
}
