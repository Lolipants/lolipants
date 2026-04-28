import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';

/// Simple CMS over the four resource families the admin backend exposes:
/// mannequins, fabrics, patterns (preset.type='pattern'), and full presets.
/// Form fields are shaped per resource per the column whitelist in admin.ts.
class AdminCmsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminCmsScreen({super.key});

  @override
  ConsumerState<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends ConsumerState<AdminCmsScreen>
    with SingleTickerProviderStateMixin {
  static const _resources = ['mannequins', 'fabrics', 'patterns', 'presets'];
  late final TabController _tabs =
      TabController(length: _resources.length, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [for (final r in _resources) Tab(text: r)],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final r in _resources) _ResourceList(resource: r),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResourceList extends ConsumerWidget {
  const _ResourceList({required this.resource});
  final String resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCmsListProvider(resource));
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminCmsListProvider(resource)),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              Text(
                formatAdminProviderError(error),
                style: AppTextStyles.bodySmall,
              ),
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
              itemBuilder: (context, i) => _ResourceRow(
                resource: resource,
                data: rows[i],
                onChanged: () =>
                    ref.invalidate(adminCmsListProvider(resource)),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cms-add-$resource',
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? existing,
  ) async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CmsFormDialog(resource: resource, initial: existing),
    );
    if (saved == null) return;
    final repo = ref.read(adminRepositoryProvider);
    final res = existing == null
        ? await repo.createCms(resource, saved)
        : await repo.updateCms(
            resource,
            existing['id'].toString(),
            saved,
          );
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, existing == null ? 'Created' : 'Updated');
        ref.invalidate(adminCmsListProvider(resource));
      },
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ResourceRow extends ConsumerWidget {
  const _ResourceRow({
    required this.resource,
    required this.data,
    required this.onChanged,
  });
  final String resource;
  final Map<String, dynamic> data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final name = _displayName();
    final preview = data['preview_url']?.toString() ??
        data['image_url']?.toString() ??
        '';
    return Card(
      child: ListTile(
        leading: preview.isNotEmpty
            ? SizedBox(
                width: 48,
                height: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(imageUrl: preview, fit: BoxFit.cover),
                ),
              )
            : const Icon(Icons.image_outlined),
        title: Text(name),
        subtitle: Text(id, style: AppTextStyles.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _ResourceList(resource: resource)
                  ._openForm(context, ref, data),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _delete(context, ref, id),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName() {
    final candidates = [
      data['label_en'],
      data['name'],
      data['name_ar'],
      data['label_ar'],
    ];
    for (final c in candidates) {
      final s = c?.toString();
      if (s != null && s.isNotEmpty) return s;
    }
    return data['id']?.toString() ?? '(unnamed)';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This removes the row from the CMS table.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    final res =
        await ref.read(adminRepositoryProvider).deleteCms(resource, id);
    res.fold(
      (err) => _snack(context, 'Failed: ${err.runtimeType}'),
      (_) {
        _snack(context, 'Deleted');
        onChanged();
      },
    );
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CmsFormDialog extends ConsumerStatefulWidget {
  const _CmsFormDialog({required this.resource, this.initial});
  final String resource;
  final Map<String, dynamic>? initial;

  @override
  ConsumerState<_CmsFormDialog> createState() => _CmsFormDialogState();
}

class _CmsFormDialogState extends ConsumerState<_CmsFormDialog> {
  late final Map<String, TextEditingController> _controllers;
  late final Map<String, bool> _bools;
  String? _imageUrl;
  bool _uploading = false;

  List<_FieldSpec> get _fields {
    switch (widget.resource) {
      case 'mannequins':
        return const [
          _FieldSpec('label_en', 'Label (EN)'),
          _FieldSpec('label_ar', 'Label (AR)'),
          _FieldSpec('sort_order', 'Sort order', isNumber: true),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('preview_url', 'Preview image', isImage: true),
        ];
      case 'fabrics':
        return const [
          _FieldSpec('name', 'Name'),
          _FieldSpec('name_ar', 'Name (AR)'),
          _FieldSpec('quality', 'Quality'),
          _FieldSpec('garment_type', 'Garment type'),
          _FieldSpec('is_available', 'Available', isBool: true),
        ];
      case 'patterns':
        return const [
          _FieldSpec('name', 'Name'),
          _FieldSpec('name_ar', 'Name (AR)'),
          _FieldSpec('garment_type', 'Garment type'),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Pattern image', isImage: true),
        ];
      case 'presets':
      default:
        return const [
          _FieldSpec('type', 'Type (style/pattern/fabric)'),
          _FieldSpec('name', 'Name'),
          _FieldSpec('name_ar', 'Name (AR)'),
          _FieldSpec('garment_type', 'Garment type'),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Image', isImage: true),
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _bools = {};
    for (final f in _fields) {
      final value = widget.initial?[f.key];
      if (f.isBool) {
        _bools[f.key] = _parseBool(value);
      } else if (f.isImage) {
        _imageUrl = value?.toString();
      } else {
        _controllers[f.key] =
            TextEditingController(text: value?.toString() ?? '');
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

  bool _parseBool(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'New ${widget.resource}'
          : 'Edit ${widget.resource}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final f in _fields) _renderField(f),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _uploading ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _renderField(_FieldSpec f) {
    if (f.isBool) {
      return SwitchListTile(
        title: Text(f.label),
        value: _bools[f.key] ?? false,
        onChanged: (v) => setState(() => _bools[f.key] = v),
      );
    }
    if (f.isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
            child: Text(f.label, style: AppTextStyles.titleSmall),
          ),
          if (_imageUrl != null && _imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: _imageUrl!,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickImage,
                icon: const Icon(Icons.upload),
                label: Text(_uploading ? 'Uploading...' : 'Upload image'),
              ),
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _imageUrl = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
            ],
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _controllers[f.key],
        keyboardType: f.isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: f.label),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final repo = ref.read(designsRepositoryProvider);
      final res = await repo.uploadPrintImage(filePath: file.path);
      if (!mounted) return;
      res.fold(
        (err) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${err.runtimeType}')),
        ),
        (url) => setState(() => _imageUrl = url),
      );
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
        if (text.isNotEmpty) {
          if (f.isNumber) {
            final n = int.tryParse(text);
            if (n != null) out[f.key] = n;
          } else {
            out[f.key] = text;
          }
        }
      }
    }
    Navigator.of(context).pop(out);
  }
}

class _FieldSpec {
  const _FieldSpec(
    this.key,
    this.label, {
    this.isBool = false,
    this.isNumber = false,
    this.isImage = false,
  });
  final String key;
  final String label;
  final bool isBool;
  final bool isNumber;
  final bool isImage;
}
