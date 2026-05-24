import 'package:lolipants/core/preferences/user_gender_provider.dart';

/// Mannequin option from admin-managed backend data.
class MannequinOption {
  const MannequinOption({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    this.previewUrl,
  });

  factory MannequinOption.fromApi(Map<String, dynamic> json) {
    return MannequinOption(
      id: json['id']?.toString() ?? '',
      labelEn: json['labelEn']?.toString() ??
          json['name']?.toString() ??
          'Mannequin',
      labelAr: json['labelAr']?.toString() ?? json['nameAr']?.toString() ?? '',
      previewUrl:
          json['previewUrl']?.toString() ?? json['preview_url']?.toString(),
    );
  }

  final String id;
  final String labelEn;
  final String labelAr;
  final String? previewUrl;
}

/// True for built-in and typical API labels for male mannequins.
bool isMaleMannequinOption(MannequinOption o) {
  final id = o.id.toLowerCase();
  if (id.endsWith('_male')) return true;
  if (o.labelEn.toLowerCase().contains('(male)')) return true;
  return false;
}

/// Orders [options] so the shopper's gender lane appears first.
List<MannequinOption> sortMannequinsForGender(
  List<MannequinOption> options,
  String? gender,
) {
  if (gender == null || gender.isEmpty) return options;
  final copy = List<MannequinOption>.from(options);
  copy.sort((a, b) {
    final aMale = isMaleMannequinOption(a);
    final bMale = isMaleMannequinOption(b);
    if (gender == UserGenderPreference.men) {
      if (aMale != bMale) return aMale ? -1 : 1;
    } else if (gender == UserGenderPreference.women) {
      if (aMale != bMale) return aMale ? 1 : -1;
    } else if (gender == UserGenderPreference.kids) {
      final aKid = _isKidsMannequinOption(a);
      final bKid = _isKidsMannequinOption(b);
      if (aKid != bKid) return aKid ? -1 : 1;
    }
    return a.labelEn.compareTo(b.labelEn);
  });
  return copy;
}

bool _isKidsMannequinOption(MannequinOption o) {
  final id = o.id.toLowerCase();
  return id == 'child' || id.contains('petite');
}
