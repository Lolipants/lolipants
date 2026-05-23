import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

/// How a configurator layer participates in unified garment tinting.
enum ConfiguratorTintRole {
  primary,
  accent,
  none,
}

/// Reads [metadata] `tintRole`; defaults to [ConfiguratorTintRole.primary].
ConfiguratorTintRole parseTintRole(Map<String, dynamic> metadata) {
  final raw = metadata['tintRole']?.toString().trim().toLowerCase();
  switch (raw) {
    case 'accent':
      return ConfiguratorTintRole.accent;
    case 'none':
      return ConfiguratorTintRole.none;
    default:
      return ConfiguratorTintRole.primary;
  }
}

/// Resolves the tint colour for [option], or null when tinting is disabled.
Color? resolveOptionTintColor({
  required ConfiguratorOption option,
  required ConfiguratorTemplate template,
  required Color primaryColour,
  required Color accentColour,
}) {
  if (!template.layerTintEnabled) return null;
  switch (option.tintRole) {
    case ConfiguratorTintRole.none:
      return null;
    case ConfiguratorTintRole.accent:
      return accentColour;
    case ConfiguratorTintRole.primary:
      return primaryColour;
  }
}

/// Wraps [child] with modulate tint when [tintColor] is non-null.
Widget applyLayerTint({required Widget child, Color? tintColor}) {
  if (tintColor == null) return child;
  return ColorFiltered(
    colorFilter: ColorFilter.mode(tintColor, BlendMode.modulate),
    child: child,
  );
}
