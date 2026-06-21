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
import 'package:lolipants/features/admin/widgets/admin_mannequin_asset_preview.dart';
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
              text: localized(
                  ref, AdminStrings.tabAssets, AdminStrings.tabAssetsAr),
            ),
            Tab(
              text: localized(
                ref,
                AdminStrings.tabConfigurator,
                AdminStrings.tabConfiguratorAr,
              ),
            ),
            Tab(
              text: localized(
                  ref, AdminStrings.tabWedding, AdminStrings.tabWeddingAr),
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
      return (
        AdminStrings.cmsHelpAccessories,
        AdminStrings.cmsHelpAccessoriesAr
      );
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
              onRefresh: () async =>
                  ref.invalidate(adminCmsListProvider(resource)),
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
    final preview =
        data['preview_url']?.toString() ?? data['image_url']?.toString() ?? '';
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
        return section != null && section.isNotEmpty
            ? '$label · $section'
            : label;
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
          localizedFromContext(
              ctx, AdminStrings.deleteTitle, AdminStrings.deleteTitleAr),
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
              localizedFromContext(
                  ctx, AdminStrings.delete, AdminStrings.deleteAr),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final locale = ref.read(settingsLocaleProvider);
    final res = await ref.read(adminRepositoryProvider).deleteCms(resource, id);
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
  _StagedCmsUpload? _stagedUpload;
  String _previewMannequinId = 'standard_female';
  bool _uploading = false;

  List<_FieldSpec> get _fields {
    switch (widget.resource) {
      case 'design-catalog':
        return const [
          _FieldSpec(
              'section_title', 'Section (e.g. Modern, Traditional — Gulf)'),
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
          _FieldSpec('swatch_url', 'Fabric swatch (square photo)',
              isImage: true),
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
          _FieldSpec('insurance_deposit', 'Insurance deposit (QAR)',
              isNumber: true),
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
    _previewMannequinId = _defaultMannequinId();
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
          onPressed: _uploading ? null : () => Navigator.of(context).pop(),
          child: Text(
            localizedFromContext(
                context, AppStrings.cancel, AppStrings.cancelAr),
          ),
        ),
        FilledButton(
          onPressed: _uploading ? null : () => _submit(),
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
      final mannequinRows =
          ref.watch(adminCmsListProvider('mannequins')).valueOrNull ?? const [];
      final previewMannequins = [
        for (final row in mannequinRows)
          if (_isActiveCmsRow(row) &&
              (row['preview_url']?.toString().trim().isNotEmpty ?? false))
            AdminPreviewMannequin.fromCmsRow(row),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 4),
            child: Text(f.label, style: AppTextStyles.titleSmall),
          ),
          AdminMannequinAssetPreview(
            stagedFile: _stagedUpload?.file,
            uploadedUrl: _imageUrl,
            mannequinId: _previewMannequinId,
            mannequins: previewMannequins,
            onMannequinChanged: (id) =>
                setState(() => _previewMannequinId = id),
            onReplace: () => _pickImage(
              toCatalog: _stagedUpload?.toCatalog ?? _supportsCatalogUpload,
            ),
            onRemove: () => setState(() {
              _stagedUpload = null;
              _imageUrl = null;
            }),
            onConfirmUpload: () => _uploadStagedImage(),
            uploading: _uploading,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (_supportsCatalogUpload)
                OutlinedButton.icon(
                  onPressed:
                      _uploading ? null : () => _pickImage(toCatalog: true),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _uploading
                        ? localized(ref, AdminStrings.uploading,
                            AdminStrings.uploadingAr)
                        : localized(
                            ref,
                            AdminStrings.uploadToCatalog,
                            AdminStrings.uploadToCatalogAr,
                          ),
                  ),
                ),
              if (_supportsCatalogUpload) const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    _uploading ? null : () => _pickImage(toCatalog: false),
                icon: const Icon(Icons.upload),
                label: Text(
                  _uploading
                      ? localized(
                          ref, AdminStrings.uploading, AdminStrings.uploadingAr)
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
          if (_stagedUpload != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _stagedUpload!.toCatalog
                    ? 'Staged for catalog upload'
                    : 'Staged for general upload',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
              ),
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
    setState(() {
      _stagedUpload = _StagedCmsUpload(file: file, toCatalog: toCatalog);
      _imageUrl = null;
      _previewMannequinId = _defaultMannequinId(file.name);
    });
  }

  Future<bool> _uploadStagedImage() async {
    final staged = _stagedUpload;
    if (staged == null) return true;
    setState(() => _uploading = true);
    try {
      if (staged.toCatalog) {
        final adminRepo = ref.read(adminRepositoryProvider);
        final res = await adminRepo.uploadCatalogAsset(
          filePath: staged.file.path,
          category: _catalogUploadCategory,
          filename: staged.file.name,
        );
        if (!mounted) return false;
        final locale = ref.read(settingsLocaleProvider);
        return res.fold(
          (err) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(formatAdminCmsError(err, locale: locale))),
            );
            return false;
          },
          (url) {
            setState(() {
              _imageUrl = url;
              _stagedUpload = null;
            });
            return true;
          },
        );
      } else {
        final repo = ref.read(designsRepositoryProvider);
        final res = await repo.uploadPrintImage(filePath: staged.file.path);
        if (!mounted) return false;
        final locale = ref.read(settingsLocaleProvider);
        return res.fold(
          (err) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(formatAdminCmsError(err, locale: locale))),
            );
            return false;
          },
          (url) {
            setState(() {
              _imageUrl = url;
              _stagedUpload = null;
            });
            return true;
          },
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!await _uploadStagedImage()) return;
    if (!mounted) return;
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

  String _defaultMannequinId([String? filename]) {
    final explicit = _controllers['gender_lane']?.text.trim().toLowerCase();
    final haystack = [
      if (explicit != null && explicit.isNotEmpty) explicit,
      widget.resource,
      filename ?? '',
      _controllers['garment_type']?.text ?? '',
      _controllers['category']?.text ?? '',
    ].join(' ').toLowerCase();
    if (haystack.contains('men') ||
        haystack.contains('male') ||
        haystack.contains('thobe')) {
      return 'standard_male';
    }
    return haystack.contains('petite') ? 'petite_female' : 'standard_female';
  }
}

class _StagedCmsUpload {
  const _StagedCmsUpload({required this.file, required this.toCatalog});

  final XFile file;
  final bool toCatalog;
}

bool _isActiveCmsRow(Map<String, dynamic> row) {
  final raw = row['is_active'] ?? row['isActive'];
  if (raw == null) return true;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  return raw.toString().toLowerCase() == 'true' || raw.toString() == '1';
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
