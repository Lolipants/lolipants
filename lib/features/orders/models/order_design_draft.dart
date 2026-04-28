/// Typed draft payload passed from editor preview to order summary.
class OrderDesignDraft {
  const OrderDesignDraft({
    this.designId,
    required this.name,
    required this.garmentType,
    required this.primaryColour,
    this.accentColour,
    this.fabricId,
    this.patternId,
    this.mannequinId,
    this.previewImageUrl,
    this.designerId,
    this.designerName,
  });

  final String? designId;
  final String name;
  final String garmentType;
  final String primaryColour;
  final String? accentColour;
  final String? fabricId;
  final String? patternId;
  final String? mannequinId;
  final String? previewImageUrl;

  /// Originating designer user id (set when ordering a showcase design).
  final String? designerId;

  /// Originating designer name (for UI attribution).
  final String? designerName;

  Map<String, dynamic> toMap() {
    return {
      'designId': designId,
      'name': name,
      'garmentType': garmentType,
      'primaryColour': primaryColour,
      'accentColour': accentColour,
      'fabricId': fabricId,
      'patternId': patternId,
      'mannequinId': mannequinId,
      'previewImageUrl': previewImageUrl,
      'designerId': designerId,
      'designerName': designerName,
    };
  }
}
