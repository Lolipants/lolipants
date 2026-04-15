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
