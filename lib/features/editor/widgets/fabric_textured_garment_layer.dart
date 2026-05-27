import 'package:flutter/material.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/utils/fabric_texture_overlay.dart';
import 'package:lolipants/features/editor/utils/layer_tint.dart';
import 'package:lolipants/features/editor/widgets/configurator_option_image.dart';

/// Configurator garment layer with optional instant fabric texture preview.
class FabricTexturedGarmentLayer extends StatelessWidget {
  const FabricTexturedGarmentLayer({
    required this.option,
    required this.template,
    required this.primaryColour,
    required this.accentColour,
    required this.fabricProvider,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    super.key,
  });

  final ConfiguratorOption option;
  final ConfiguratorTemplate template;
  final Color primaryColour;
  final Color accentColour;
  final ImageProvider? fabricProvider;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final tintColor = resolveOptionTintColor(
      option: option,
      template: template,
      primaryColour: primaryColour,
      accentColour: accentColour,
    );

    final fabric = fabricProvider;
    final maskProvider = configuratorOptionImageProvider(option);
    final useFabric = fabric != null &&
        maskProvider != null &&
        effectiveTintRole(option) == ConfiguratorTintRole.primary;

    final maskWidget = ConfiguratorOptionImage(
      option: option,
      tintColor: useFabric ? null : tintColor,
      fit: fit,
      alignment: alignment,
    );

    if (useFabric) {
      return FabricTextureOverlay(
        maskImageProvider: maskProvider,
        fabricImageProvider: fabric,
        fit: fit,
        alignment: alignment,
        loadingChild: maskWidget,
      );
    }

    return maskWidget;
  }
}
