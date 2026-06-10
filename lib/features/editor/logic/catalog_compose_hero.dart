import 'package:lolipants/features/editor/providers/editor_provider.dart';

/// Whether the Compose / layers hero should show the design-catalogue flat-lay.
///
/// Only true in [EditorBuildStyleMode.catalog] — not when a configurator template
/// (modest abaya, western dress, etc.) is active, even if
/// [EditorState.selectedCatalogDesignPath] is still set from a prior session.
bool showsCatalogComposeHero(EditorState editor) {
  if (editor.heroMode != EditorHeroMode.compose) return false;
  return editor.buildStyleMode == EditorBuildStyleMode.catalog;
}
