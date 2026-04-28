/// Designer profile snapshot for designer detail/profile screens.
class DesignerProfile {
  /// Creates a designer profile.
  const DesignerProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.speciality,
    this.followerCount = 0,
    this.isProDesigner = false,
    this.isFollowing = false,
    this.publicDesigns = 0,
    this.ordersEarned = 0,
  });

  /// Parses API payload from GET /designers/:id.
  factory DesignerProfile.fromApi(Map<String, dynamic> json) {
    final stats = json['stats'];
    return DesignerProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Designer',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      speciality: json['speciality']?.toString(),
      followerCount: _asInt(json['followerCount']) ??
          _asInt(json['follower_count']) ??
          0,
      isProDesigner:
          json['isProDesigner'] == true || _asInt(json['is_pro_designer']) == 1,
      isFollowing: json['isFollowing'] == true,
      publicDesigns: stats is Map
          ? (_asInt(stats['publicDesigns']) ?? _asInt(stats['public_designs']) ?? 0)
          : 0,
      ordersEarned: stats is Map
          ? (_asInt(stats['ordersEarned']) ?? _asInt(stats['orders_earned']) ?? 0)
          : 0,
    );
  }

  /// User id.
  final String id;

  /// Display name.
  final String name;

  /// Optional avatar url.
  final String? avatarUrl;

  /// Short bio.
  final String? bio;

  /// Designer speciality tag.
  final String? speciality;

  /// Total follower count.
  final int followerCount;

  /// Pro-designer flag (renders gold tick).
  final bool isProDesigner;

  /// Whether the current viewer already follows this designer.
  final bool isFollowing;

  /// Count of public designs.
  final int publicDesigns;

  /// Orders earned (ordered-by-others on this designer's designs).
  final int ordersEarned;

  /// Copy helper.
  DesignerProfile copyWith({
    bool? isFollowing,
    int? followerCount,
  }) {
    return DesignerProfile(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      bio: bio,
      speciality: speciality,
      followerCount: followerCount ?? this.followerCount,
      isProDesigner: isProDesigner,
      isFollowing: isFollowing ?? this.isFollowing,
      publicDesigns: publicDesigns,
      ordersEarned: ordersEarned,
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  if (value is String) return int.tryParse(value);
  return null;
}
