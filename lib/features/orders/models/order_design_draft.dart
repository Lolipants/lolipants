/// Typed draft payload passed from editor preview to order summary.
class OrderDesignDraft {
  const OrderDesignDraft({
    required this.name,
    required this.garmentType,
    required this.primaryColour,
    this.accentColour,
    this.fabricId,
    this.patternId,
    this.mannequinId,
  });

  final String name;
  final String garmentType;
  final String primaryColour;
  final String? accentColour;
  final String? fabricId;
  final String? patternId;
  final String? mannequinId;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'garmentType': garmentType,
      'primaryColour': primaryColour,
      'accentColour': accentColour,
      'fabricId': fabricId,
      'patternId': patternId,
      'mannequinId': mannequinId,
    };
  }
}
