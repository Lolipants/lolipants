import 'package:lolipants/core/preferences/user_gender_provider.dart';

/// Resolves browse / design gender lane from editor mannequin id.
String mannequinGenderLane(String mannequinId) {
  final id = mannequinId.trim().toLowerCase();
  if (id.isEmpty) return UserGenderPreference.women;
  if (id == 'child' || id.contains('kid')) {
    return UserGenderPreference.kids;
  }
  if (id.contains('male') && !id.contains('female')) {
    return UserGenderPreference.men;
  }
  if (id.contains('female') || id.contains('femal') || id.contains('curvey')) {
    return UserGenderPreference.women;
  }
  return UserGenderPreference.women;
}
