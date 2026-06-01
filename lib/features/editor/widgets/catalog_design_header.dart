import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/editor_panel_header.dart';
import 'package:lolipants/features/editor/widgets/editor_style_dropdown.dart';

/// Compact style dropdown + All/Traditional/Modern/Casual chips (one row).
class CatalogDesignHeader extends ConsumerWidget {
  const CatalogDesignHeader({
    required this.templates,
    required this.mannequinId,
    this.template,
    this.catalogOnly = false,
    this.onReset,
    this.embedded = false,
    super.key,
  });

  final List<ConfiguratorTemplate> templates;
  final String mannequinId;
  final ConfiguratorTemplate? template;
  final bool catalogOnly;
  final VoidCallback? onReset;
  final bool embedded;

  static const _modes = <DesignCatalogFilter>[
    DesignCatalogFilter.all,
    DesignCatalogFilter.traditional,
    DesignCatalogFilter.modern,
    if (kFeatureCasual) DesignCatalogFilter.casual,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return EditorPanelHeader(
      embedded: embedded,
      leading: EditorStyleDropdown(
        templates: templates,
        mannequinId: mannequinId,
        selectedTemplateId: template?.id ?? '',
        buildStyleMode: editor.buildStyleMode,
        catalogOnly: catalogOnly,
        dense: true,
        onReset: onReset,
      ),
      chips: [
        for (final mode in _modes)
          EditorHeaderChipData(
            label: designCatalogFilterLabel(mode),
            selected: editor.catalogFilter == mode,
            onTap: () => notifier.setCatalogFilter(mode),
          ),
      ],
    );
  }
}
