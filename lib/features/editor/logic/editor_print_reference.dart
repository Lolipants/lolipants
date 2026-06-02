import 'package:lolipants/core/assets/catalog_image_uri.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';

/// True when [printPathOrUrl] is an AI/save catalogue or compose reference, not
/// user-placed artwork on the hero.
bool isEditorReferencePrintImage({
  required String? printPathOrUrl,
  String? catalogDesignPath,
  Map<String, dynamic>? renderMetadata,
}) {
  final print = printPathOrUrl?.trim() ?? '';
  if (print.isEmpty) return false;

  final meta = renderMetadata ?? const <String, dynamic>{};
  for (final key in ['catalogFlatImageUrl', 'configuratorComposeImageUrl']) {
    final ref = meta[key]?.toString().trim() ?? '';
    if (ref.isNotEmpty && print == ref) return true;
  }

  final catalog = catalogDesignPath?.trim() ?? '';
  if (catalog.isNotEmpty) {
    if (print == catalog) return true;

    final display = catalogDesignDisplayPath(catalog);
    if (print == display) return true;

    final flat = catalogFlatlayPathFor(catalog);
    if (print == flat) return true;

    final lookFallback = catalogLookRenderFallbackPath(display);
    if (lookFallback != null && print == lookFallback) return true;

    for (final candidate in [catalog, display, flat, lookFallback]) {
      if (candidate == null || candidate.isEmpty) continue;
      final url = _catalogNetworkUrl(candidate);
      if (url != null && print == url) return true;
    }

    final printTail = _fileTail(print);
    if (printTail == 'catalog-flat.png' ||
        printTail == 'configurator-compose.png') {
      return true;
    }
    for (final candidate in [catalog, display, flat, lookFallback]) {
      if (candidate == null || candidate.isEmpty) continue;
      if (printTail == _fileTail(candidate)) return true;
    }
  }

  if (print.contains('configurator-compose') || print.contains('catalog-flat')) {
    return true;
  }

  return false;
}

String? _catalogNetworkUrl(String pathOrUrl) {
  try {
    return catalogImageNetworkUrl(pathOrUrl);
  } on Object {
    return null;
  }
}

String _fileTail(String pathOrUrl) {
  final trimmed = pathOrUrl.trim();
  final q = trimmed.indexOf('?');
  final withoutQuery = q >= 0 ? trimmed.substring(0, q) : trimmed;
  final slash = withoutQuery.lastIndexOf('/');
  return (slash >= 0 ? withoutQuery.substring(slash + 1) : withoutQuery)
      .toLowerCase();
}
