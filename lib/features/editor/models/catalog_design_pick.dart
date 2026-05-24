/// A pickable flat-lay in the editor design catalog (bundled or CMS).
class CatalogDesignPick {
  const CatalogDesignPick({
    required this.ref,
    required this.label,
    required this.imageSource,
  });

  /// Stable id: bundled asset path or `design-catalog:{uuid}`.
  final String ref;

  final String label;

  /// Passed to [CatalogImage.path] (asset path or HTTPS URL).
  final String imageSource;
}

/// Section title + flat-lay picks for [CatalogDesignPicker].
typedef CatalogDesignSection = (String sectionTitle, List<CatalogDesignPick> items);

const String kDesignCatalogRefPrefix = 'design-catalog:';

/// CMS-backed catalog ref for [id].
String designCatalogRef(String id) => '$kDesignCatalogRefPrefix$id';

/// Whether [ref] points at a CMS design catalog row.
bool isCmsDesignCatalogRef(String ref) => ref.startsWith(kDesignCatalogRefPrefix);

/// Parses CMS id from [ref], or null when bundled.
String? cmsDesignCatalogId(String ref) {
  if (!isCmsDesignCatalogRef(ref)) return null;
  final id = ref.substring(kDesignCatalogRefPrefix.length).trim();
  return id.isEmpty ? null : id;
}
