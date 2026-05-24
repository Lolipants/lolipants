import 'package:lolipants/features/editor/utils/ai_colour_parse.dart';

/// AI-generated design suggestion from `/ai/design`.
class GarmentDesignSuggestion {
  /// Creates a design suggestion.
  const GarmentDesignSuggestion({
    required this.primaryColour,
    this.accentColour,
    this.fabricId,
    this.patternId,
    this.description,
    this.descriptionAr,
  });

  /// Parses API response payload.
  factory GarmentDesignSuggestion.fromApi(Map<String, dynamic> json) {
    final accentRaw = json['accentColour']?.toString();
    return GarmentDesignSuggestion(
      primaryColour: normalizeAiColourHex(
        json['primaryColour']?.toString(),
      ),
      accentColour: accentRaw == null || accentRaw.trim().isEmpty
          ? null
          : normalizeAiColourHex(accentRaw),
      fabricId: json['fabricId']?.toString(),
      patternId: json['patternId']?.toString(),
      description: json['description']?.toString(),
      descriptionAr: json['descriptionAr']?.toString(),
    );
  }

  /// Main suggested color hex.
  final String primaryColour;

  /// Optional accent color hex.
  final String? accentColour;

  /// Optional suggested fabric id.
  final String? fabricId;

  /// Optional suggested pattern id.
  final String? patternId;

  /// Optional English explanation.
  final String? description;

  /// Optional Arabic explanation.
  final String? descriptionAr;
}
