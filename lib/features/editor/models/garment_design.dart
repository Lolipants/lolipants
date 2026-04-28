import 'dart:convert';

/// Saved user design coming from `/designs`.
class GarmentDesign {
  /// Creates a design snapshot.
  const GarmentDesign({
    required this.id,
    required this.name,
    required this.garmentType,
    required this.primaryColour,
    this.fabricId,
    this.fabricQuality,
    this.accentColour,
    this.patternId,
    this.printImageUrl,
    this.presetStyleId,
    this.mannequinId,
    this.renderMetadata,
    this.isPublic = false,
  });

  /// Parses API payload.
  factory GarmentDesign.fromApi(Map<String, dynamic> json) {
    Map<String, dynamic>? parseRenderMetadata(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is String && value.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map<String, dynamic>) return decoded;
        } on FormatException {
          return null;
        }
      }
      return null;
    }

    return GarmentDesign(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      garmentType: json['garment_type']?.toString() ??
          json['garmentType']?.toString() ??
          'thobe',
      primaryColour: json['primary_colour']?.toString() ??
          json['primaryColour']?.toString() ??
          '#162F28',
      fabricId: json['fabric_id']?.toString() ?? json['fabricId']?.toString(),
      fabricQuality: json['fabric_quality']?.toString() ??
          json['fabricQuality']?.toString(),
      accentColour:
          json['accent_colour']?.toString() ?? json['accentColour']?.toString(),
      patternId:
          json['pattern_id']?.toString() ?? json['patternId']?.toString(),
      printImageUrl: json['print_image_url']?.toString() ??
          json['printImageUrl']?.toString(),
      presetStyleId: json['preset_style_id']?.toString() ??
          json['presetStyleId']?.toString(),
      mannequinId:
          json['mannequin_id']?.toString() ?? json['mannequinId']?.toString(),
      renderMetadata: parseRenderMetadata(json['render_metadata'] ?? json['renderMetadata']),
      isPublic: (json['is_public'] == 1) || json['isPublic'] == true,
    );
  }

  /// Design identifier.
  final String id;

  /// User-visible design name.
  final String name;

  /// Garment kind (`thobe`, `abaya`, ...).
  final String garmentType;

  /// Main garment colour hex string.
  final String primaryColour;

  /// Optional fabric identifier.
  final String? fabricId;

  /// Optional quality tier.
  final String? fabricQuality;

  /// Optional accent colour hex string.
  final String? accentColour;

  /// Optional pattern identifier.
  final String? patternId;

  /// Optional print image URL.
  final String? printImageUrl;

  /// Optional preset style identifier.
  final String? presetStyleId;

  /// Optional mannequin option id.
  final String? mannequinId;

  /// Canonical renderer metadata payload from the API.
  final Map<String, dynamic>? renderMetadata;

  /// Public showcase flag.
  final bool isPublic;
}
