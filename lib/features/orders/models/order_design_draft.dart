/// Typed draft payload passed from editor preview to order summary.
class OrderDesignDraft {
  const OrderDesignDraft({
    this.designId,
    required this.name,
    required this.garmentType,
    required this.primaryColour,
    this.accentColour,
    this.fabricId,
    this.fabricQuality,
    this.patternId,
    this.mannequinId,
    this.previewImageUrl,
    this.designerId,
    this.designerName,
    this.configuratorSummary,
  });

  final String? designId;
  final String name;
  final String garmentType;
  final String primaryColour;
  final String? accentColour;
  final String? fabricId;

  /// Editor fabric tier (`standard` / `premium` / `suit_grade`); display-only in checkout.
  final String? fabricQuality;

  final String? patternId;
  final String? mannequinId;
  final String? previewImageUrl;

  /// Originating designer user id (set when ordering a showcase design).
  final String? designerId;

  /// Originating designer name (for UI attribution).
  final String? designerName;

  /// Human-readable configurator summary from the editor.
  final String? configuratorSummary;

  Map<String, dynamic> toMap() {
    return {
      'designId': designId,
      'name': name,
      'garmentType': garmentType,
      'primaryColour': primaryColour,
      'accentColour': accentColour,
      'fabricId': fabricId,
      'fabricQuality': fabricQuality,
      'patternId': patternId,
      'mannequinId': mannequinId,
      'previewImageUrl': previewImageUrl,
      'designerId': designerId,
      'designerName': designerName,
      'configuratorSummary': configuratorSummary,
    };
  }
}
