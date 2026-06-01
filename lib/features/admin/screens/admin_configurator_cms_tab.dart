import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/features/admin/utils/admin_cms_helpers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';

/// Selectable parent row for template/slot filter and create forms.
class _ParentOption {
  const _ParentOption({required this.id, required this.label});

  final String id;
  final String label;
}

List<_ParentOption> _templateOptions(List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) return null;
        final name = row['name_en']?.toString().trim();
        final label = (name != null && name.isNotEmpty) ? '$name ($id)' : id;
        return _ParentOption(id: id, label: label);
      })
      .whereType<_ParentOption>()
      .toList(growable: false);
}

List<_ParentOption> _slotOptions(List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final id = row['id']?.toString() ?? '';
        if (id.isEmpty) return null;
        final title = row['title_en']?.toString().trim();
        final key = row['slot_key']?.toString().trim();
        final prefix = title ?? key ?? id;
        return _ParentOption(id: id, label: '$prefix ($id)');
      })
      .whereType<_ParentOption>()
      .toList(growable: false);
}

/// CMS for configurator templates, slots, and options.
class AdminConfiguratorCmsTab extends ConsumerStatefulWidget {
  const AdminConfiguratorCmsTab({super.key});

  @override
  ConsumerState<AdminConfiguratorCmsTab> createState() =>
      _AdminConfiguratorCmsTabState();
}

class _AdminConfiguratorCmsTabState extends ConsumerState<AdminConfiguratorCmsTab>
    with SingleTickerProviderStateMixin {
  static const _resources = [
    'configurator_templates',
    'configurator_slots',
    'configurator_options',
  ];

  late final TabController _tabs =
      TabController(length: _resources.length, vsync: this);
  String? _filterTemplateId;
  String? _filterSlotId;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resource = _resources[_tabs.index];
    final templates = ref
            .watch(
              adminConfiguratorListProvider(
                const AdminConfiguratorFilter(resource: 'configurator_templates'),
              ),
            )
            .valueOrNull ??
        const [];
    final slots = ref
            .watch(
              adminConfiguratorListProvider(
                AdminConfiguratorFilter(
                  resource: 'configurator_slots',
                  templateId: _filterTemplateId,
                ),
              ),
            )
            .valueOrNull ??
        const [];
    return Column(
      children: [
        Material(
          color: AppColors.smoke,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              localized(
                ref,
                AdminStrings.configuratorHelpBanner,
                AdminStrings.configuratorHelpBannerAr,
              ),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(
              text: localized(
                ref,
                AdminStrings.tabTemplates,
                AdminStrings.tabTemplatesAr,
              ),
            ),
            Tab(
              text: localized(ref, AdminStrings.tabSlot, AdminStrings.tabSlotAr),
            ),
            Tab(
              text: localized(ref, AdminStrings.tabOptions, AdminStrings.tabOptionsAr),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [for (final r in _resources) _buildTabBody(r)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FloatingActionButton.extended(
            heroTag: 'cfg-add-$resource',
            onPressed: () => _openForm(
              context,
              resource,
              null,
              templates: templates,
              slots: slots,
            ),
            icon: const Icon(Icons.add),
            label: Text(localized(ref, AdminStrings.newItem, AdminStrings.newItemAr)),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody(String resource) {
    final filter = AdminConfiguratorFilter(
      resource: resource,
      templateId: resource == 'configurator_slots' ? _filterTemplateId : null,
      slotId: resource == 'configurator_options' ? _filterSlotId : null,
    );
    final async = ref.watch(adminConfiguratorListProvider(filter));
    final templatesAsync = ref.watch(
      adminConfiguratorListProvider(
        const AdminConfiguratorFilter(resource: 'configurator_templates'),
      ),
    );
    final slotsAsync = ref.watch(
      adminConfiguratorListProvider(
        AdminConfiguratorFilter(
          resource: 'configurator_slots',
          templateId: _filterTemplateId,
        ),
      ),
    );

    return Column(
      children: [
        if (resource == 'configurator_slots')
          _ParentFilterBar(
            labelEn: AdminStrings.filterTemplate,
            labelAr: AdminStrings.filterTemplateAr,
            value: _filterTemplateId,
            options: _templateOptions(templatesAsync.valueOrNull ?? const []),
            onChanged: (v) => setState(() => _filterTemplateId = v),
          ),
        if (resource == 'configurator_options') ...[
          _ParentFilterBar(
            labelEn: AdminStrings.filterTemplate,
            labelAr: AdminStrings.filterTemplateAr,
            value: _filterTemplateId,
            options: _templateOptions(templatesAsync.valueOrNull ?? const []),
            onChanged: (v) => setState(() {
              _filterTemplateId = v;
              _filterSlotId = null;
            }),
          ),
          _ParentFilterBar(
            labelEn: AdminStrings.tabSlot,
            labelAr: AdminStrings.tabSlotAr,
            value: _filterSlotId,
            options: _slotOptions(slotsAsync.valueOrNull ?? const []),
            onChanged: (v) => setState(() => _filterSlotId = v),
          ),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminConfiguratorListProvider(filter)),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(formatAdminProviderError(e), style: AppTextStyles.bodySmall),
                ],
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Center(
                        child: Text(
                          '${localized(ref, AdminStrings.noResourcePrefix, AdminStrings.noResourcePrefixAr)}$resource${localized(ref, AdminStrings.noResourceSuffix, AdminStrings.noResourceSuffixAr)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => _ConfiguratorRow(
                    resource: resource,
                    data: rows[i],
                    onEdit: () => _openForm(
                      context,
                      resource,
                      rows[i],
                      templates: templatesAsync.valueOrNull ?? const [],
                      slots: slotsAsync.valueOrNull ?? const [],
                    ),
                    onChanged: () =>
                        ref.invalidate(adminConfiguratorListProvider(filter)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm(
    BuildContext context,
    String resource,
    Map<String, dynamic>? existing, {
    required List<Map<String, dynamic>> templates,
    required List<Map<String, dynamic>> slots,
  }) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ConfiguratorFormDialog(
        resource: resource,
        initial: existing,
        templateOptions: _templateOptions(templates),
        slotOptions: _slotOptions(slots),
        defaultTemplateId: _filterTemplateId,
        defaultSlotId: _filterSlotId,
      ),
    );
    if (saved == null || !context.mounted) return;
    final repo = ref.read(adminRepositoryProvider);
    final filter = AdminConfiguratorFilter(
      resource: resource,
      templateId:
          resource == 'configurator_slots' ? _filterTemplateId : null,
      slotId: resource == 'configurator_options' ? _filterSlotId : null,
    );
    final result = existing == null
        ? await repo.createConfiguratorCms(resource, saved)
        : await repo.updateConfiguratorCms(
            resource,
            existing['id']?.toString() ?? '',
            saved,
          );
    if (!context.mounted) return;
    final locale = ref.read(settingsLocaleProvider);
    result.fold(
      (err) => _snack(context, formatAdminCmsError(err, locale: locale)),
      (_) {
        _snack(
          context,
          localized(
            ref,
            existing == null ? AdminStrings.created : AdminStrings.updated,
            existing == null ? AdminStrings.createdAr : AdminStrings.updatedAr,
          ),
        );
        ref.invalidate(adminConfiguratorListProvider(filter));
        invalidatePublicCmsCache(ref, resource);
      },
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ParentFilterBar extends ConsumerWidget {
  const _ParentFilterBar({
    required this.labelEn,
    required this.labelAr,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String labelEn;
  final String labelAr;
  final String? value;
  final List<_ParentOption> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = options.map((o) => o.id).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            localized(ref, labelEn, labelAr),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: value != null && ids.contains(value) ? value : null,
              hint: Text(
                localized(ref, AdminStrings.filterAll, AdminStrings.filterAllAr),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    localized(ref, AdminStrings.filterAll, AdminStrings.filterAllAr),
                  ),
                ),
                for (final option in options)
                  DropdownMenuItem(
                    value: option.id,
                    child: Text(option.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfiguratorRow extends ConsumerWidget {
  const _ConfiguratorRow({
    required this.resource,
    required this.data,
    required this.onEdit,
    required this.onChanged,
  });

  final String resource;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final title = data['name_en']?.toString() ??
        data['title_en']?.toString() ??
        data['label_en']?.toString() ??
        id;
    final thumb = data['asset_url']?.toString() ??
        data['preview_url']?.toString();
    return Card(
      child: ListTile(
        leading: thumb != null && thumb.startsWith('http')
            ? SizedBox(
                width: 48,
                height: 48,
                child: CachedNetworkImage(
                  imageUrl: thumb,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined),
                ),
              )
            : const Icon(Icons.layers_outlined),
        title: Text(title, style: AppTextStyles.bodyMedium),
        subtitle: Text(id, style: AppTextStyles.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, id, onChanged),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    VoidCallback onChanged,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          localizedFromContext(ctx, AdminStrings.deleteTitle, AdminStrings.deleteTitleAr),
        ),
        content: Text(
          localizedFromContext(
            ctx,
            AdminStrings.configuratorDeleteBody,
            AdminStrings.configuratorDeleteBodyAr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              localizedFromContext(ctx, AppStrings.cancel, AppStrings.cancelAr),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              localizedFromContext(ctx, AdminStrings.delete, AdminStrings.deleteAr),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final locale = ref.read(settingsLocaleProvider);
    final res = await ref
        .read(adminRepositoryProvider)
        .deleteConfiguratorCms(resource, id);
    if (!context.mounted) return;
    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatAdminCmsError(err, locale: locale))),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(ref, AdminStrings.deleted, AdminStrings.deletedAr),
            ),
          ),
        );
        onChanged();
        invalidatePublicCmsCache(ref, resource);
      },
    );
  }
}

class _ConfiguratorFormDialog extends ConsumerStatefulWidget {
  const _ConfiguratorFormDialog({
    required this.resource,
    this.initial,
    this.templateOptions = const [],
    this.slotOptions = const [],
    this.defaultTemplateId,
    this.defaultSlotId,
  });

  final String resource;
  final Map<String, dynamic>? initial;
  final List<_ParentOption> templateOptions;
  final List<_ParentOption> slotOptions;
  final String? defaultTemplateId;
  final String? defaultSlotId;

  @override
  ConsumerState<_ConfiguratorFormDialog> createState() =>
      _ConfiguratorFormDialogState();
}

class _ConfiguratorFormDialogState
    extends ConsumerState<_ConfiguratorFormDialog> {
  late final Map<String, TextEditingController> _controllers;
  final Map<String, bool> _bools = {};
  String? _imageUrl;
  bool _uploading = false;
  String? _selectedTemplateId;
  String? _selectedSlotId;

  List<_CfgField> get _fields {
    switch (widget.resource) {
      case 'configurator_templates':
        return const [
          _CfgField('id', 'Id (optional on create)', optional: true),
          _CfgField('name_en', 'Name (EN)'),
          _CfgField('name_ar', 'Name (AR)'),
          _CfgField('garment_type', 'Garment type'),
          _CfgField('region_tag', 'Region tag (modest/western)'),
          _CfgField('sort_order', 'Sort order', isNumber: true),
          _CfgField('required_slot_keys', 'Required slot keys (JSON array)'),
          _CfgField('is_active', 'Active', isBool: true),
        ];
      case 'configurator_slots':
        return const [
          _CfgField('template_id', 'Template'),
          _CfgField('slot_key', 'Slot key'),
          _CfgField('title_en', 'Title (EN)'),
          _CfgField('title_ar', 'Title (AR)'),
          _CfgField('sort_order', 'Sort order', isNumber: true),
          _CfgField('is_active', 'Active', isBool: true),
        ];
      case 'configurator_options':
      default:
        return const [
          _CfgField('slot_id', 'Slot'),
          _CfgField('option_key', 'Option key'),
          _CfgField('label_en', 'Label (EN)'),
          _CfgField('label_ar', 'Label (AR)'),
          _CfgField('asset_url', 'Asset URL', isImage: true),
          _CfgField('metadata_json', 'Metadata JSON'),
          _CfgField('sort_order', 'Sort order', isNumber: true),
          _CfgField('is_active', 'Active', isBool: true),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _selectedTemplateId = widget.initial?['template_id']?.toString() ??
        widget.defaultTemplateId;
    _selectedSlotId =
        widget.initial?['slot_id']?.toString() ?? widget.defaultSlotId;
    for (final f in _fields) {
      if (f.isBool) {
        final v = widget.initial?[f.key];
        _bools[f.key] = v == 1 || v == true;
      } else if (f.isImage) {
        _imageUrl = widget.initial?['asset_url']?.toString();
      } else if (f.key == 'template_id' || f.key == 'slot_id') {
        continue;
      } else {
        _controllers[f.key] = TextEditingController(
          text: widget.initial?[f.key]?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial == null;
    return AlertDialog(
      title: Text(
        isNew
            ? localized(ref, AdminStrings.newItem, AdminStrings.newItemAr)
            : localized(ref, AdminStrings.editLabel, AdminStrings.editLabelAr),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in _fields) ...[
                if (f.isBool)
                  SwitchListTile(
                    title: Text(f.label),
                    value: _bools[f.key] ?? false,
                    onChanged: (v) => setState(() => _bools[f.key] = v),
                  )
                else if (f.isImage)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_imageUrl != null && _imageUrl!.startsWith('http'))
                        CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          height: 80,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const SizedBox(
                            height: 80,
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      Row(
                        children: [
                          if (widget.resource == 'configurator_options')
                            OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : () => _pickImage(toCatalog: true),
                              icon: const Icon(Icons.cloud_upload_outlined),
                              label: Text(
                                _uploading
                                    ? localized(
                                        ref,
                                        AdminStrings.uploading,
                                        AdminStrings.uploadingAr,
                                      )
                                    : localized(
                                        ref,
                                        AdminStrings.uploadToCatalog,
                                        AdminStrings.uploadToCatalogAr,
                                      ),
                              ),
                            ),
                          if (widget.resource == 'configurator_options')
                            const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _uploading
                                ? null
                                : () => _pickImage(toCatalog: false),
                            icon: _uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(
                              widget.resource == 'configurator_options'
                                  ? (_uploading
                                      ? localized(
                                          ref,
                                          AdminStrings.uploading,
                                          AdminStrings.uploadingAr,
                                        )
                                      : localized(
                                          ref,
                                          AdminStrings.uploadGeneral,
                                          AdminStrings.uploadGeneralAr,
                                        ))
                                  : localized(
                                      ref,
                                      AdminStrings.uploadImage,
                                      AdminStrings.uploadImageAr,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else if (f.key == 'metadata_json' &&
                    widget.resource == 'configurator_options')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controllers[f.key],
                        decoration: InputDecoration(labelText: f.label),
                        maxLines: 6,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Example: {"assetPath": "assets/images/configurator/cfg_mod_sleeve_bell_NEUTRAL.png", "layerZ": 2, "tintRole": "primary"}\n'
                        'tintRole: primary | accent | none (default primary).\n'
                        'Use neutral gray/ivory assets (~#E8E4EA) with shading preserved; same canvas size and layerZ per template.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.fog,
                            ),
                      ),
                    ],
                  )
                else if (f.key == 'template_id' &&
                    widget.resource == 'configurator_slots')
                  _parentDropdown(
                    label: f.label,
                    value: _selectedTemplateId,
                    options: widget.templateOptions,
                    onChanged: (v) => setState(() => _selectedTemplateId = v),
                  )
                else if (f.key == 'slot_id' &&
                    widget.resource == 'configurator_options')
                  _parentDropdown(
                    label: f.label,
                    value: _selectedSlotId,
                    options: widget.slotOptions,
                    onChanged: (v) => setState(() => _selectedSlotId = v),
                  )
                else if (f.key == 'template_id' || f.key == 'slot_id')
                  const SizedBox.shrink()
                else
                  TextField(
                    controller: _controllers[f.key],
                    decoration: InputDecoration(labelText: f.label),
                    keyboardType:
                        f.isNumber ? TextInputType.number : TextInputType.text,
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
        ),
      ],
    );
  }

  Widget _parentDropdown({
    required String label,
    required String? value,
    required List<_ParentOption> options,
    required ValueChanged<String?> onChanged,
  }) {
    final ids = options.map((o) => o.id).toList(growable: false);
    final resolved = value != null && ids.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      value: resolved,
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.id,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }

  Future<void> _pickImage({required bool toCatalog}) async {
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      if (toCatalog) {
        final res = await ref.read(adminRepositoryProvider).uploadCatalogAsset(
              filePath: file.path,
              category: 'configurator',
              filename: file.name,
            );
        if (!mounted) return;
        final locale = ref.read(settingsLocaleProvider);
        res.fold(
          (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(formatAdminCmsError(err, locale: locale))),
          ),
          (url) => setState(() => _imageUrl = url),
        );
      } else {
        final res = await ref
            .read(designsRepositoryProvider)
            .uploadPrintImage(filePath: file.path);
        if (!mounted) return;
        final locale = ref.read(settingsLocaleProvider);
        res.fold(
          (err) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(formatAdminCmsError(err, locale: locale))),
          ),
          (url) => setState(() => _imageUrl = url),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final out = <String, dynamic>{};
    if (widget.resource == 'configurator_slots' &&
        _selectedTemplateId != null &&
        _selectedTemplateId!.isNotEmpty) {
      out['template_id'] = _selectedTemplateId;
    }
    if (widget.resource == 'configurator_options' &&
        _selectedSlotId != null &&
        _selectedSlotId!.isNotEmpty) {
      out['slot_id'] = _selectedSlotId;
    }
    for (final f in _fields) {
      if (f.isBool) {
        out[f.key] = (_bools[f.key] ?? false) ? 1 : 0;
      } else if (f.isImage) {
        if (_imageUrl != null && _imageUrl!.isNotEmpty) {
          out[f.key] = _imageUrl;
        }
      } else {
        final text = _controllers[f.key]?.text.trim() ?? '';
        if (text.isNotEmpty || !f.optional) {
          if (f.isNumber) {
            final n = int.tryParse(text);
            if (n != null) out[f.key] = n;
          } else {
            out[f.key] = text;
          }
        }
      }
    }
    Navigator.pop(context, out);
  }
}

class _CfgField {
  const _CfgField(
    this.key,
    this.label, {
    this.isBool = false,
    this.isNumber = false,
    this.isImage = false,
    this.optional = false,
  });

  final String key;
  final String label;
  final bool isBool;
  final bool isNumber;
  final bool isImage;
  final bool optional;
}
