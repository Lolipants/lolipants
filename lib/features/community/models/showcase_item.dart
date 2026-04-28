/// Public design exposed in the marketplace showcase grid.
class ShowcaseItem {
  /// Creates a showcase item.
  const ShowcaseItem({
    required this.designId,
    required this.name,
    required this.garmentType,
    required this.primaryColour,
    required this.designer,
    this.accentColour,
    this.fabricQuality,
    this.previewImageUrl,
    this.orderCount = 0,
    this.trendingScore = 0,
    required this.createdAt,
  });

  /// Parses API payload from GET /showcase.
  factory ShowcaseItem.fromApi(Map<String, dynamic> json) {
    final designer = json['designer'];
    return ShowcaseItem(
      designId: json['designId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Design',
      garmentType: json['garmentType']?.toString() ?? 'other',
      primaryColour: json['primaryColour']?.toString() ?? '#C9A84C',
      accentColour: json['accentColour']?.toString(),
      fabricQuality: json['fabricQuality']?.toString(),
      previewImageUrl: json['previewImageUrl']?.toString(),
      orderCount: _asInt(json['orderCount']) ?? 0,
      trendingScore: _asInt(json['trendingScore']) ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      designer: designer is Map<String, dynamic>
          ? ShowcaseDesignerMini.fromApi(designer)
          : const ShowcaseDesignerMini(id: '', name: 'Designer'),
    );
  }

  /// Backend design id.
  final String designId;

  /// Display name.
  final String name;

  /// Garment type (abaya/thobe/...).
  final String garmentType;

  /// Primary colour in hex.
  final String primaryColour;

  /// Optional accent colour hex.
  final String? accentColour;

  /// Fabric quality tag.
  final String? fabricQuality;

  /// Optional preview/mannequin thumbnail url.
  final String? previewImageUrl;

  /// Total orders on this design.
  final int orderCount;

  /// Computed backend trending score.
  final int trendingScore;

  /// Created timestamp (used to sort 'newest').
  final DateTime createdAt;

  /// Designer summary.
  final ShowcaseDesignerMini designer;
}

/// Minimal designer summary attached to a showcase item.
class ShowcaseDesignerMini {
  /// Creates a designer mini summary.
  const ShowcaseDesignerMini({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isProDesigner = false,
  });

  /// Parses API payload.
  factory ShowcaseDesignerMini.fromApi(Map<String, dynamic> json) {
    return ShowcaseDesignerMini(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Designer',
      avatarUrl: json['avatarUrl']?.toString(),
      isProDesigner: json['isProDesigner'] == true,
    );
  }

  /// User id.
  final String id;

  /// Display name.
  final String name;

  /// Optional avatar URL.
  final String? avatarUrl;

  /// Whether this designer is a Pro.
  final bool isProDesigner;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
