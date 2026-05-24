import 'package:lolipants/features/editor/models/catalog_design_pick.dart';

/// CMS-managed editor flat-lay design.
class DesignCatalogItem {
  const DesignCatalogItem({
    required this.id,
    required this.sectionTitle,
    required this.labelEn,
    required this.labelAr,
    required this.imageUrl,
    this.garmentType,
    this.genderLane,
    this.sortOrder = 0,
  });

  factory DesignCatalogItem.fromJson(Map<String, dynamic> json) {
    return DesignCatalogItem(
      id: json['id']?.toString() ?? '',
      sectionTitle: json['sectionTitle']?.toString() ??
          json['section_title']?.toString() ??
          'Catalog',
      labelEn: json['labelEn']?.toString() ?? json['label_en']?.toString() ?? '',
      labelAr: json['labelAr']?.toString() ?? json['label_ar']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      garmentType: json['garmentType']?.toString() ?? json['garment_type']?.toString(),
      genderLane: json['genderLane']?.toString() ?? json['gender_lane']?.toString(),
      sortOrder: (json['sortOrder'] is num)
          ? (json['sortOrder'] as num).toInt()
          : (json['sort_order'] is num)
              ? (json['sort_order'] as num).toInt()
              : 0,
    );
  }

  final String id;
  final String sectionTitle;
  final String labelEn;
  final String labelAr;
  final String imageUrl;
  final String? garmentType;
  final String? genderLane;
  final int sortOrder;

  String get catalogRef => 'design-catalog:$id';

  CatalogDesignPick toPick() => CatalogDesignPick(
        ref: catalogRef,
        label: labelEn,
        imageSource: imageUrl,
      );
}
