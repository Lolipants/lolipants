import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/home/widgets/design_gender_dialog.dart';

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
  if (current != null && UserGenderPreference.all.contains(current)) {
    return current;
  }

  if (!context.mounted) return null;
  final picked = await showDesignGenderDialog(context);
  if (picked == null) return null;

  await notifier.persistGender(picked);
  return picked;
}
