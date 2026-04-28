/// API-backed fabric metadata used by editor controls.
class FabricOption {
  const FabricOption({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.quality,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String nameAr;
  final String quality;
  final bool isAvailable;

  factory FabricOption.fromApi(Map<String, dynamic> json) {
    return FabricOption(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
      nameAr: json['name_ar']?.toString().trim() ??
          json['nameAr']?.toString().trim() ??
          '',
      quality: json['quality']?.toString().trim() ?? 'standard',
      isAvailable: (json['is_available'] == 1) ||
          (json['isAvailable'] == true) ||
          (json['is_available']?.toString() == '1'),
    );
  }
}
