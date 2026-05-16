import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';

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
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Templates'),
            Tab(text: 'Slots'),
            Tab(text: 'Options'),
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
            onPressed: () => _openForm(context, resource, null),
            icon: const Icon(Icons.add),
            label: const Text('New'),
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
            label: 'Template id',
            value: _filterTemplateId,
            items: templatesAsync.valueOrNull
                    ?.map((r) => r['id']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(growable: false) ??
                const [],
            onChanged: (v) => setState(() => _filterTemplateId = v),
          ),
        if (resource == 'configurator_options') ...[
          _ParentFilterBar(
            label: 'Template id',
            value: _filterTemplateId,
            items: templatesAsync.valueOrNull
                    ?.map((r) => r['id']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(growable: false) ??
                const [],
            onChanged: (v) => setState(() {
              _filterTemplateId = v;
              _filterSlotId = null;
            }),
          ),
          _ParentFilterBar(
            label: 'Slot id',
            value: _filterSlotId,
            items: slotsAsync.valueOrNull
                    ?.map((r) => r['id']?.toString() ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList(growable: false) ??
                const [],
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
                        child: Text('No $resource yet.',
                            style: AppTextStyles.bodyMedium),
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
                    onEdit: () => _openForm(context, resource, rows[i]),
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
    Map<String, dynamic>? existing,
  ) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ConfiguratorFormDialog(
        resource: resource,
        initial: existing,
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
    result.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, existing == null ? 'Created' : 'Updated');
        ref.invalidate(adminConfiguratorListProvider(filter));
      },
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ParentFilterBar extends StatelessWidget {
  const _ParentFilterBar({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: value != null && items.contains(value) ? value : null,
              hint: const Text('All'),
              items: [
                const DropdownMenuItem<String?>(child: Text('All')),
                for (final id in items)
                  DropdownMenuItem(value: id, child: Text(id)),
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
                child: CachedNetworkImage(imageUrl: thumb, fit: BoxFit.cover),
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
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This removes the row from the configurator tables.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final res = await ref
        .read(adminRepositoryProvider)
        .deleteConfiguratorCms(resource, id);
    if (!context.mounted) return;
    res.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${err.runtimeType}')),
      ),
      (_) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Deleted')));
        onChanged();
      },
    );
  }
}

class _ConfiguratorFormDialog extends ConsumerStatefulWidget {
  const _ConfiguratorFormDialog({required this.resource, this.initial});

  final String resource;
  final Map<String, dynamic>? initial;

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
          _CfgField('template_id', 'Template id'),
          _CfgField('slot_key', 'Slot key'),
          _CfgField('title_en', 'Title (EN)'),
          _CfgField('title_ar', 'Title (AR)'),
          _CfgField('sort_order', 'Sort order', isNumber: true),
          _CfgField('is_active', 'Active', isBool: true),
        ];
      case 'configurator_options':
      default:
        return const [
          _CfgField('slot_id', 'Slot id'),
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
    for (final f in _fields) {
      if (f.isBool) {
        final v = widget.initial?[f.key];
        _bools[f.key] = v == 1 || v == true;
      } else if (f.isImage) {
        _imageUrl = widget.initial?['asset_url']?.toString();
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
    return AlertDialog(
      title: Text(widget.initial == null ? 'New' : 'Edit'),
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
                        ),
                      TextButton.icon(
                        onPressed: _uploading ? null : _pickImage,
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload),
                        label: const Text('Upload image'),
                      ),
                    ],
                  )
                else
                  TextField(
                    controller: _controllers[f.key],
                    decoration: InputDecoration(labelText: f.label),
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
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  Future<void> _pickImage() async {
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final res = await ref
          .read(designsRepositoryProvider)
          .uploadPrintImage(filePath: file.path);
      if (!mounted) return;
      res.fold((_) {}, (url) => setState(() => _imageUrl = url));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _submit() {
    final out = <String, dynamic>{};
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
