import 'package:lolipants/features/editor/models/configurator_catalog.dart';

/// Offline fallback when `GET /configurator/templates` is unavailable.
ConfiguratorCatalog bundledConfiguratorCatalog() {
  return ConfiguratorCatalog.fromApi(_bundledJson);
}

const List<Map<String, dynamic>> _bundledJson = [
  {
    'id': 'modest_abaya_v1',
    'nameEn': 'Modest abaya',
    'nameAr': 'عباءة محتشمة',
    'garmentType': 'abaya',
    'regionTag': 'modest',
    'sortOrder': 0,
    'requiredSlotKeys': ['sleeve_length', 'collar_style'],
    'slots': [
      {
        'id': 'slot_modest_sleeve',
        'slotKey': 'sleeve_length',
        'titleEn': 'Sleeve length',
        'titleAr': 'طول الكم',
        'sortOrder': 0,
        'options': [
          {
            'id': 'opt_modest_sleeve_wide',
            'optionKey': 'wide',
            'labelEn': 'Wide sleeves',
            'labelAr': 'أكمام واسعة',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_gulf_abaya_black_closed.png',
              'layerZ': 1,
            },
            'sortOrder': 0,
          },
          {
            'id': 'opt_modest_sleeve_fitted',
            'optionKey': 'fitted',
            'labelEn': 'Fitted sleeves',
            'labelAr': 'أكمام ضيقة',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_mod_abaya_slate_tech.png',
              'layerZ': 1,
            },
            'sortOrder': 1,
          },
        ],
      },
      {
        'id': 'slot_modest_collar',
        'slotKey': 'collar_style',
        'titleEn': 'Collar',
        'titleAr': 'الياقة',
        'sortOrder': 1,
        'options': [
          {
            'id': 'opt_modest_collar_high',
            'optionKey': 'high_neck',
            'labelEn': 'High neck band',
            'labelAr': 'ياقة عالية',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_gulf_abaya_navy_champagne.png',
              'layerZ': 2,
            },
            'sortOrder': 0,
          },
          {
            'id': 'opt_modest_collar_open',
            'optionKey': 'open_front',
            'labelEn': 'Open front cardigan',
            'labelAr': 'أمام مفتوح',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_gulf_abaya_cardigan_charcoal.png',
              'layerZ': 2,
            },
            'sortOrder': 1,
          },
        ],
      },
    ],
  },
  {
    'id': 'western_dress_v1',
    'nameEn': 'Western dress',
    'nameAr': 'فستان غربي',
    'garmentType': 'dress',
    'regionTag': 'western',
    'sortOrder': 1,
    'requiredSlotKeys': ['bodice', 'sleeve'],
    'slots': [
      {
        'id': 'slot_west_bodice',
        'slotKey': 'bodice',
        'titleEn': 'Bodice',
        'titleAr': 'الصدر',
        'sortOrder': 0,
        'options': [
          {
            'id': 'opt_west_bodice_classic',
            'optionKey': 'classic_tiffany',
            'labelEn': 'Classic Tiffany',
            'labelAr': 'تيفاني كلاسيك',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_mod_abaya_butterfly_white.png',
              'layerZ': 1,
            },
            'sortOrder': 0,
          },
          {
            'id': 'opt_west_bodice_sweetheart',
            'optionKey': 'sweetheart',
            'labelEn': 'Sweetheart',
            'labelAr': 'ياقة قلب',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_mod_abaya_plum_satin.png',
              'layerZ': 1,
            },
            'sortOrder': 1,
          },
        ],
      },
      {
        'id': 'slot_west_sleeve',
        'slotKey': 'sleeve',
        'titleEn': 'Sleeve',
        'titleAr': 'الكم',
        'sortOrder': 1,
        'options': [
          {
            'id': 'opt_west_sleeve_none',
            'optionKey': 'sleeveless',
            'labelEn': 'Sleeveless',
            'labelAr': 'بدون أكمام',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_casual_tee_crew_white.png',
              'layerZ': 2,
            },
            'sortOrder': 0,
          },
          {
            'id': 'opt_west_sleeve_cap',
            'optionKey': 'cap',
            'labelEn': 'Cap sleeve',
            'labelAr': 'كم قصير',
            'metadata': {
              'assetPath':
                  'assets/images/designs/design_casual_longsleeve_crew_white.png',
              'layerZ': 2,
            },
            'sortOrder': 1,
          },
        ],
      },
    ],
  },
];
