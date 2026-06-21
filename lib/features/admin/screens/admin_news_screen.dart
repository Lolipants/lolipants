import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/admin_strings.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/core/permissions/device_permission_prompt.dart';
import 'package:lolipants/features/admin/providers/admin_providers.dart';
import 'package:lolipants/shared/widgets/labeled_floating_action_button.dart';

/// Admin CRUD for fashion news articles.
class AdminNewsScreen extends ConsumerWidget {
  const AdminNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminNewsProvider);
    return Scaffold(
      backgroundColor: AppColors.ink,
      floatingActionButton: LabeledFloatingActionButton(
        heroTag: 'admin-news-create',
        icon: Icons.add,
        labelEn: AdminStrings.newsNewArticle,
        labelAr: AdminStrings.newsNewArticleAr,
        onPressed: () => _openEditor(context, ref),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              formatAdminProviderError(error),
              style: AppTextStyles.bodySmall,
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                localized(ref, AdminStrings.newsNoArticles, AdminStrings.newsNoArticlesAr),
                style: AppTextStyles.bodyMedium,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminNewsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final row = rows[index];
                final title = row['titleEn']?.toString() ??
                    row['title_en']?.toString() ??
                    '—';
                final published = row['isPublished'] == true ||
                    row['is_published'] == 1;
                final featured = row['isFeatured'] == true ||
                    row['is_featured'] == 1;
                return ListTile(
                  tileColor: AppColors.ember,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  title: Text(title, style: AppTextStyles.titleSmall),
                  subtitle: Text(
                    published ? 'Published' : 'Draft',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.fog),
                  ),
                  trailing: featured
                      ? const Icon(Icons.star, color: AppColors.gold, size: 18)
                      : null,
                  onTap: () => _openEditor(context, ref, existing: row),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ember,
      builder: (sheetContext) => _NewsEditorSheet(
        existing: existing,
        onSaved: () => ref.invalidate(adminNewsProvider),
      ),
    );
  }
}

class _NewsEditorSheet extends ConsumerStatefulWidget {
  const _NewsEditorSheet({this.existing, required this.onSaved});

  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NewsEditorSheet> createState() => _NewsEditorSheetState();
}

class _NewsEditorSheetState extends ConsumerState<_NewsEditorSheet> {
  late final TextEditingController _titleEn;
  late final TextEditingController _titleAr;
  late final TextEditingController _summaryEn;
  late final TextEditingController _summaryAr;
  late final TextEditingController _bodyEn;
  late final TextEditingController _bodyAr;
  late bool _published;
  late bool _featured;
  String? _coverUrl;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleEn = TextEditingController(text: e?['titleEn']?.toString() ?? '');
    _titleAr = TextEditingController(text: e?['titleAr']?.toString() ?? '');
    _summaryEn = TextEditingController(text: e?['summaryEn']?.toString() ?? '');
    _summaryAr = TextEditingController(text: e?['summaryAr']?.toString() ?? '');
    _bodyEn = TextEditingController(text: e?['bodyEn']?.toString() ?? '');
    _bodyAr = TextEditingController(text: e?['bodyAr']?.toString() ?? '');
    _published = e?['isPublished'] == true || e?['is_published'] == 1;
    _featured = e?['isFeatured'] == true || e?['is_featured'] == 1;
    _coverUrl = e?['coverImageUrl']?.toString() ?? e?['cover_image_url']?.toString();
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _summaryEn.dispose();
    _summaryAr.dispose();
    _bodyEn.dispose();
    _bodyAr.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() => {
        'titleEn': _titleEn.text.trim(),
        'titleAr': _titleAr.text.trim(),
        'summaryEn': _summaryEn.text.trim(),
        'summaryAr': _summaryAr.text.trim(),
        'bodyEn': _bodyEn.text.trim(),
        'bodyAr': _bodyAr.text.trim(),
        'coverImageUrl': _coverUrl,
        'isPublished': _published,
        'isFeatured': _featured,
      };

  Future<void> _save() async {
    if (_titleEn.text.trim().isEmpty || _titleAr.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final repo = ref.read(adminRepositoryProvider);
    final id = widget.existing?['id']?.toString();
    final result = id == null
        ? await repo.createNews(_payload())
        : await repo.updateNews(id, _payload());
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatAdminProviderError(e))),
      ),
      (_) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(ref, AdminStrings.newsSaved, AdminStrings.newsSavedAr),
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete() async {
    final id = widget.existing?['id']?.toString();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          localized(ref, AdminStrings.newsDeleteConfirm, AdminStrings.newsDeleteConfirmAr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localizedFromContext(ctx, AppStrings.cancel, AppStrings.cancelAr)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(localized(ref, AdminStrings.delete, AdminStrings.deleteAr)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(adminRepositoryProvider).deleteNews(id);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatAdminProviderError(e))),
      ),
      (_) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localized(ref, AdminStrings.newsDeleted, AdminStrings.newsDeletedAr),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCover() async {
    final allowed = await DevicePermissionPrompt.ensureForImageSource(
      context,
      ImageSource.gallery,
    );
    if (!allowed || !mounted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final upload = await ref.read(adminRepositoryProvider).uploadNewsAsset(
          filePath: picked.path,
          filename: picked.name,
        );
    if (!mounted) return;
    upload.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatAdminProviderError(e))),
      ),
      (url) => setState(() => _coverUrl = url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, bottom + AppSpacing.md),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localized(
                ref,
                widget.existing == null
                    ? AdminStrings.newsNewArticle
                    : AdminStrings.newsEditArticle,
                widget.existing == null
                    ? AdminStrings.newsNewArticleAr
                    : AdminStrings.newsEditArticleAr,
              ),
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _field(_titleEn, AdminStrings.newsTitleEn, AdminStrings.newsTitleEnAr),
            _field(_titleAr, AdminStrings.newsTitleArLabel, AdminStrings.newsTitleArLabelAr),
            _field(_summaryEn, AdminStrings.newsSummaryEn, AdminStrings.newsSummaryEnAr, maxLines: 2),
            _field(_summaryAr, AdminStrings.newsSummaryArLabel, AdminStrings.newsSummaryArLabelAr, maxLines: 2),
            _field(_bodyEn, AdminStrings.newsBodyEn, AdminStrings.newsBodyEnAr, maxLines: 6),
            _field(_bodyAr, AdminStrings.newsBodyArLabel, AdminStrings.newsBodyArLabelAr, maxLines: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localized(ref, AdminStrings.newsPublished, AdminStrings.newsPublishedAr)),
              value: _published,
              onChanged: (v) => setState(() => _published = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(localized(ref, AdminStrings.newsFeatured, AdminStrings.newsFeaturedAr)),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            if (_coverUrl != null && _coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(imageUrl: _coverUrl!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                localized(ref, AdminStrings.newsPickImage, AdminStrings.newsPickImageAr),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(localized(ref, AdminStrings.save, AdminStrings.saveAr)),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _delete,
                child: Text(
                  localized(ref, AdminStrings.delete, AdminStrings.deleteAr),
                  style: const TextStyle(color: AppColors.rubyLight),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String labelEn,
    String labelAr, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: localized(ref, labelEn, labelAr),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
