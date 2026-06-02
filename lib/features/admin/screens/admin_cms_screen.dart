import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/features/admin/screens/admin_configurator_cms_tab.dart';
import 'package:lolipants/features/admin/utils/admin_cms_helpers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/shared/widgets/labeled_floating_action_button.dart';

/// CMS for catalogue assets (mannequins, fabrics, patterns, presets) and the
/// modular configurator (templates → slots → options).
class AdminCmsScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const AdminCmsScreen({super.key});

  @override
  ConsumerState<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends ConsumerState<AdminCmsScreen>
    with TickerProviderStateMixin {
  static const _assetResources = [
    'design-catalog',
    'mannequins',
    'fabrics',
    'patterns',
    'presets',
  ];
  late final TabController _sectionTabs = TabController(length: 4, vsync: this);
  late final TabController _assetTabs =
      TabController(length: _assetResources.length, vsync: this);

  @override
  void dispose() {
    _sectionTabs.dispose();
    _assetTabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _sectionTabs,
          tabs: [
            Tab(
              text: localized(ref, AdminStrings.tabAssets, AdminStrings.tabAssetsAr),
            ),
            Tab(
              text: localized(
                ref,
                AdminStrings.tabConfigurator,
                AdminStrings.tabConfiguratorAr,
              ),
            ),
            Tab(
              text: localized(ref, AdminStrings.tabWedding, AdminStrings.tabWeddingAr),
            ),
            Tab(
              text: localized(
                ref,
                AdminStrings.tabAccessories,
                AdminStrings.tabAccessoriesAr,
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _sectionTabs,
            children: [
              Column(
                children: [
                  TabBar(
                    controller: _assetTabs,
                    isScrollable: true,
                    tabs: [for (final r in _assetResources) Tab(text: r)],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _assetTabs,
                      children: [
                        for (final r in _assetResources)
                          _ResourceList(resource: r),
                      ],
                    ),
                  ),
                ],
              ),
              const AdminConfiguratorCmsTab(),
              const _ResourceList(resource: 'wedding-dresses'),
              const _ResourceList(resource: 'accessories'),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isMannequinCmsReadOnly(String resource) =>
    resource == 'mannequins' && !kFeatureAdminMannequinCms;

(String, String)? _cmsResourceHelp(String resource) {
  switch (resource) {
    case 'design-catalog':
      return (
        AdminStrings.cmsHelpDesignCatalog,
        AdminStrings.cmsHelpDesignCatalogAr,
      );
    case 'mannequins':
      return (AdminStrings.cmsHelpMannequins, AdminStrings.cmsHelpMannequinsAr);
    case 'presets':
      return (AdminStrings.cmsHelpPresets, AdminStrings.cmsHelpPresetsAr);
    case 'patterns':
      return (AdminStrings.cmsHelpPatterns, AdminStrings.cmsHelpPatternsAr);
    case 'fabrics':
      return (AdminStrings.cmsHelpFabrics, AdminStrings.cmsHelpFabricsAr);
    case 'accessories':
      return (AdminStrings.cmsHelpAccessories, AdminStrings.cmsHelpAccessoriesAr);
    default:
      return null;
  }
}

class _CmsHelpBanner extends ConsumerWidget {
  const _CmsHelpBanner({required this.messageEn, required this.messageAr});

  final String messageEn;
  final String messageAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.smoke,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Text(
          localized(ref, messageEn, messageAr),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
        ),
      ),
    );
  }
}

class _ResourceList extends ConsumerWidget {
  const _ResourceList({required this.resource});
  final String resource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCmsListProvider(resource));
    final readOnly = _isMannequinCmsReadOnly(resource);
    final help = _cmsResourceHelp(resource);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (help != null)
            _CmsHelpBanner(messageEn: help.$1, messageAr: help.$2),
          Expanded(
            child: RefreshIndicator(
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
              itemBuilder: (context, i) => _ResourceRow(
                resource: resource,
                data: rows[i],
                readOnly: readOnly,
                onChanged: () =>
                    ref.invalidate(adminCmsListProvider(resource)),
              ),
            );
          },
        ),
            ),
          ),
        ],
      ),
      floatingActionButton: readOnly
          ? null
          : LabeledFloatingActionButton(
              heroTag: 'cms-add-$resource',
              icon: Icons.add,
              labelEn: AdminStrings.newItem,
              labelAr: AdminStrings.newItemAr,
              onPressed: () => _openForm(context, ref, null),
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
    final locale = ref.read(settingsLocaleProvider);
    res.fold(
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
        ref.invalidate(adminCmsListProvider(resource));
        invalidatePublicCmsCache(ref, resource);
        if (resource == 'patterns') {
          ref.invalidate(adminCmsListProvider('presets'));
        }
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
    this.readOnly = false,
  });
  final String resource;
  final Map<String, dynamic> data;
  final VoidCallback onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final name = _displayName(ref);
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
                  child: CachedNetworkImage(
                    imageUrl: preview,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ),
              )
            : const Icon(Icons.image_outlined),
        title: Text(name),
        subtitle: Text(
          resource == 'wedding-dresses'
              ? '${data['category'] ?? ''} · rent ${data['rent_price_per_day']}/day · '
                  'sale ${data['sale_price']} · deposit ${data['insurance_deposit']}'
              : resource == 'accessories'
                  ? '${data['category'] ?? ''} · ${data['sale_price']} QAR · '
                      'addon ${data['allow_addon'] == 1 ? 'yes' : 'no'}'
                  : id,
          style: AppTextStyles.bodySmall,
        ),
        trailing: readOnly
            ? null
            : Row(
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

  String _displayName(WidgetRef ref) {
    if (resource == 'design-catalog') {
      final section = data['section_title']?.toString();
      final label = data['label_en']?.toString();
      if (label != null && label.isNotEmpty) {
        return section != null && section.isNotEmpty ? '$label · $section' : label;
      }
    }
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
    return data['id']?.toString() ??
        localized(ref, AdminStrings.unnamed, AdminStrings.unnamedAr);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          localizedFromContext(ctx, AdminStrings.deleteTitle, AdminStrings.deleteTitleAr),
        ),
        content: Text(
          localizedFromContext(
            ctx,
            AdminStrings.deleteCmsBody,
            AdminStrings.deleteCmsBodyAr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              localizedFromContext(ctx, AppStrings.cancel, AppStrings.cancelAr),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              localizedFromContext(ctx, AdminStrings.delete, AdminStrings.deleteAr),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final locale = ref.read(settingsLocaleProvider);
    final res =
        await ref.read(adminRepositoryProvider).deleteCms(resource, id);
    res.fold(
      (err) => _snack(context, formatAdminCmsError(err, locale: locale)),
      (_) {
        _snack(
          context,
          localizedFromContext(
            context,
            AdminStrings.deleted,
            AdminStrings.deletedAr,
          ),
        );
        onChanged();
        invalidatePublicCmsCache(ref, resource);
        if (resource == 'patterns') {
          ref.invalidate(adminCmsListProvider('presets'));
        }
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
      case 'design-catalog':
        return const [
          _FieldSpec('section_title', 'Section (e.g. Modern, Traditional — Gulf)'),
          _FieldSpec('label_en', 'Label (EN)'),
          _FieldSpec('label_ar', 'Label (AR)'),
          _FieldSpec('garment_type', 'Garment type (abaya, thobe, dress…)'),
          _FieldSpec(
            'gender_lane',
            'Gender lane (women, men, kids — optional)',
            optional: true,
          ),
          _FieldSpec('sort_order', 'Sort order', isNumber: true),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Flat-lay image', isImage: true),
        ];
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
          _FieldSpec('swatch_url', 'Fabric swatch (square photo)', isImage: true),
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
        return const [
          _FieldSpec('type', 'Type (style/casual/pattern/fabric)'),
          _FieldSpec('name', 'Name'),
          _FieldSpec('name_ar', 'Name (AR)'),
          _FieldSpec('garment_type', 'Garment type'),
          _FieldSpec(
            'region',
            'Region (gulf/levant/maghreb/modern/casual)',
          ),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Image', isImage: true),
        ];
      case 'wedding-dresses':
        return const [
          _FieldSpec('label_en', 'Label (EN)'),
          _FieldSpec('label_ar', 'Label (AR)'),
          _FieldSpec('category', 'Category (wedding_dress / bridesmaid)'),
          _FieldSpec('rent_price_per_day', 'Rent / day (QAR)', isNumber: true),
          _FieldSpec('sale_price', 'Sale price (QAR)', isNumber: true),
          _FieldSpec('insurance_deposit', 'Insurance deposit (QAR)', isNumber: true),
          _FieldSpec('sort_order', 'Sort order', isNumber: true),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Dress image', isImage: true),
        ];
      case 'accessories':
        return const [
          _FieldSpec('label_en', 'Label (EN)'),
          _FieldSpec('label_ar', 'Label (AR)'),
          _FieldSpec('category', 'Category (scarf / bag / jewellery / other)'),
          _FieldSpec('sale_price', 'Sale price (QAR)', isNumber: true),
          _FieldSpec('description_en', 'Description (EN)', optional: true),
          _FieldSpec('description_ar', 'Description (AR)', optional: true),
          _FieldSpec('allow_addon', 'Allow garment add-on', isBool: true),
          _FieldSpec('sort_order', 'Sort order', isNumber: true),
          _FieldSpec('is_active', 'Active', isBool: true),
          _FieldSpec('image_url', 'Product image', isImage: true),
        ];
      default:
        return const [
          _FieldSpec('name', 'Name'),
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
    final isNew = widget.initial == null;
    return AlertDialog(
      title: Text(
        isNew
            ? '${localized(ref, AdminStrings.newItem, AdminStrings.newItemAr)} ${widget.resource}'
            : '${localized(ref, AdminStrings.editLabel, AdminStrings.editLabelAr)} ${widget.resource}',
      ),
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
          child: Text(
            localizedFromContext(context, AppStrings.cancel, AppStrings.cancelAr),
          ),
        ),
        FilledButton(
          onPressed: _uploading ? null : _submit,
          child: Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
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
                errorWidget: (_, __, ___) => const SizedBox(
                  height: 120,
                  child: Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          Row(
            children: [
              if (_supportsCatalogUpload)
                OutlinedButton.icon(
                  onPressed: _uploading ? null : () => _pickImage(toCatalog: true),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _uploading
                        ? localized(ref, AdminStrings.uploading, AdminStrings.uploadingAr)
                        : localized(
                            ref,
                            AdminStrings.uploadToCatalog,
                            AdminStrings.uploadToCatalogAr,
                          ),
                  ),
                ),
              if (_supportsCatalogUpload) const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _uploading ? null : () => _pickImage(toCatalog: false),
                icon: const Icon(Icons.upload),
                label: Text(
                  _uploading
                      ? localized(ref, AdminStrings.uploading, AdminStrings.uploadingAr)
                      : localized(
                          ref,
                          AdminStrings.uploadGeneral,
                          AdminStrings.uploadGeneralAr,
                        ),
                ),
              ),
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _imageUrl = null),
                  icon: const Icon(Icons.close),
                  label: Text(
                    localized(ref, AdminStrings.remove, AdminStrings.removeAr),
                  ),
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

  bool get _supportsCatalogUpload {
    switch (widget.resource) {
      case 'design-catalog':
      case 'patterns':
      case 'presets':
      case 'wedding-dresses':
      case 'accessories':
        return true;
      default:
        return false;
    }
  }

  String get _catalogUploadCategory {
    switch (widget.resource) {
      case 'design-catalog':
      case 'patterns':
      case 'presets':
      case 'wedding-dresses':
      case 'accessories':
        return 'designs';
      default:
        return 'designs';
    }
  }

  Future<void> _pickImage({required bool toCatalog}) async {
    final granted = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!granted) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      if (toCatalog) {
        final adminRepo = ref.read(adminRepositoryProvider);
        final res = await adminRepo.uploadCatalogAsset(
          filePath: file.path,
          category: _catalogUploadCategory,
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
        final repo = ref.read(designsRepositoryProvider);
        final res = await repo.uploadPrintImage(filePath: file.path);
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
    this.optional = false,
  });
  final String key;
  final String label;
  final bool isBool;
  final bool isNumber;
  final bool isImage;
  final bool optional;
}
