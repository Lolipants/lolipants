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
    return GarmentDesignSuggestion(
      primaryColour: json['primaryColour']?.toString() ?? '#162F28',
      accentColour: json['accentColour']?.toString(),
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
