import 'package:flutter_dotenv/flutter_dotenv.dart';

/// When true, catalogue PNGs load from the app bundle instead of R2 (local dev).
const bool kFeatureBundledCatalogAssets = bool.fromEnvironment(
  'FEATURE_BUNDLED_CATALOG_ASSETS',
  defaultValue: false,
);

/// R2 public base URL from `.env` (`CLOUDFLARE_R2_BASE_URL`), no trailing slash.
String? get catalogCdnBaseUrl {
  final raw = dotenv.env['CLOUDFLARE_R2_BASE_URL']?.trim() ?? '';
  if (raw.isEmpty) return null;
  return raw.replaceAll(RegExp(r'/+$'), '');
}

/// Whether bundled design / mannequin / configurator paths should resolve to R2.
bool get useRemoteCatalogAssets {
  if (kFeatureBundledCatalogAssets) return false;
  final base = catalogCdnBaseUrl;
  return base != null && base.isNotEmpty;
}

/// True for paths under `assets/images/designs|mannequins|configurator|fabrics/`.
bool isCatalogAssetPath(String path) {
  final p = path.trim();
  return p.startsWith('assets/images/designs/') ||
      p.startsWith('assets/images/mannequins/') ||
      p.startsWith('assets/images/configurator/') ||
      p.startsWith('assets/images/fabrics/');
}

/// Maps a bundled catalogue path to an R2 URL, or returns [pathOrUrl] unchanged.
///
/// Objects are stored at `catalog/{designs|mannequins|configurator}/<file>`.
String resolveCatalogImageUri(String pathOrUrl) {
  final p = pathOrUrl.trim();
  if (p.isEmpty) return p;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (useRemoteCatalogAssets && isCatalogAssetPath(p)) {
    final base = catalogCdnBaseUrl!;
    final relative = p.substring('assets/images/'.length);
    return '$base/catalog/$relative';
  }
  return p;
}

/// URI suitable for [Image.network] / [CachedNetworkImage].
String? catalogImageNetworkUrl(String pathOrUrl) {
  final resolved = resolveCatalogImageUri(pathOrUrl);
  if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
    return resolved;
  }
  return null;
}

/// Local asset path when not using remote catalogue hosting.
String? catalogImageAssetPath(String pathOrUrl) {
  final resolved = resolveCatalogImageUri(pathOrUrl);
  if (resolved.startsWith('assets/')) return resolved;
  return null;
}

/// Bundled asset path for [pathOrUrl], bypassing CDN remapping.
///
/// Returns the shipped `assets/...` path whenever the input points at a
/// bundled asset, so callers can fall back to the local copy if a remote
/// (R2) load fails. Returns null for remote URLs or filesystem paths.
String? bundledCatalogAssetPath(String pathOrUrl) {
  final p = pathOrUrl.trim();
  if (p.startsWith('assets/')) return p;
  return null;
}
