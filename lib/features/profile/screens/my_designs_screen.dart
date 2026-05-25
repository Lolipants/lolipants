import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/utils/publish_showcase_feedback.dart';
import 'package:lolipants/features/community/widgets/publish_showcase_dialog.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/data/editor_design_restore.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/providers/design_catalog_providers.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/features/editor/utils/ai_colour_parse.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/catalog_image.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Lists saved user designs from the backend.
class MyDesignsScreen extends ConsumerStatefulWidget {
  const MyDesignsScreen({super.key});

  @override
  ConsumerState<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends ConsumerState<MyDesignsScreen> {
  bool _isCreating = false;
  String? _deletingDesignId;

  @override
  Widget build(BuildContext context) {
    final designsState = ref.watch(myDesignsProvider);
    final designs = designsState.valueOrNull ?? const <GarmentDesign>[];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myDesigns)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : () => _openCreateDesignSheet(context),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('New design'),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          RefreshIndicator(
            onRefresh: () => ref.read(myDesignsProvider.notifier).reload(),
            child: designs.isEmpty && !designsState.isLoading
                ? ListView(
                    children: const [
                      SizedBox(height: 220),
                      Center(child: Text('No designs saved yet')),
                    ],
                  )
                : GridView.builder(
                    // Bottom padding reserves space for the extended FAB so
                    // the last row is not hidden behind it.
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      96,
                    ),
                    itemCount: designs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final design = designs[index];
                      return _DesignTile(
                        design: design,
                        deleting: _deletingDesignId == design.id,
                        onTap: () => _openDesign(design),
                        onDelete: () => _confirmDelete(design),
                        onPublish: () => _publishDesign(design),
                        onUnpublish: () => _unpublishDesign(design),
                      );
                    },
                  ),
          ),
          LoadingOverlay(visible: designsState.isLoading && designs.isNotEmpty),
        ],
      ),
    );
  }

  void _openDesign(GarmentDesign design) {
    context.push('/editor', extra: design);
  }

  Future<void> _confirmDelete(GarmentDesign design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete design?'),
          content: Text(
            'This will permanently delete "${design.name}". This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.deleteDesign(design.id);
    if (!mounted) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            designErrorMessage(error, fallback: 'Could not delete design.'),
          ),
        ),
      ),
      (_) {
        ref.read(myDesignsProvider.notifier).reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design deleted')),
        );
      },
    );
  }

  Future<void> _publishDesign(GarmentDesign design) async {
    final preview = designPreviewImageSource(design);
    final confirmed = await showPublishShowcaseDialog(
      context,
      design: design,
      commissionPct: 10,
      previewImageUrl: preview?.source.startsWith('http') == true
          ? preview!.source
          : null,
    );
    if (confirmed != true || !mounted) return;
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.publishDesign(design.id);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            designErrorMessage(e, fallback: 'Could not publish design.'),
          ),
        ),
      ),
      (payload) {
        ref.read(myDesignsProvider.notifier).reload();
        notifyShowcasePublishSuccess(
          ref,
          context,
          commissionPct: payload.commissionPct,
        );
      },
    );
  }

  Future<void> _unpublishDesign(GarmentDesign design) async {
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.unpublishDesign(design.id);
    if (!mounted) return;
    result.fold(
      (e) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            designErrorMessage(e, fallback: 'Could not unpublish design.'),
          ),
        ),
      ),
      (_) {
        ref.read(myDesignsProvider.notifier).reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Showcase')),
        );
      },
    );
  }

  Future<void> _openCreateDesignSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final garmentController = TextEditingController(text: 'thobe');
    final colourController = TextEditingController(text: '#162F28');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: AppSpacing.lg,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New design draft', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              LolipantsTextField(
                label: 'Design name',
                controller: nameController,
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsTextField(
                label: 'Garment type (e.g. thobe)',
                controller: garmentController,
              ),
              const SizedBox(height: AppSpacing.sm),
              LolipantsTextField(
                label: 'Primary colour hex',
                controller: colourController,
              ),
              const SizedBox(height: AppSpacing.md),
              LolipantsButton(
                label: 'Create',
                loading: _isCreating,
                onPressed: () async {
                  final name = nameController.text.trim();
                  final garment = garmentController.text.trim();
                  final colour = colourController.text.trim();
                  if (name.isEmpty || garment.isEmpty || colour.isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  await _createDraft(
                    context: sheetContext,
                    name: name,
                    garmentType: garment,
                    primaryColour: colour,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createDraft({
    required BuildContext context,
    required String name,
    required String garmentType,
    required String primaryColour,
  }) async {
    setState(() => _isCreating = true);
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.createDesign(
      payload: {
        'name': name,
        'garmentType': garmentType,
        'primaryColour': primaryColour,
      },
    );
    setState(() => _isCreating = false);

    if (!context.mounted) return;
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            designErrorMessage(
              error,
              fallback: 'Could not save design draft',
            ),
          ),
        ),
      ),
      (_) async {
        await ref.read(myDesignsProvider.notifier).reload();
        if (!context.mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design draft saved')),
        );
      },
    );
  }
}

class _DesignTile extends StatelessWidget {
  const _DesignTile({
    required this.design,
    required this.onTap,
    required this.onDelete,
    required this.onPublish,
    required this.onUnpublish,
    this.deleting = false,
  });

  final GarmentDesign design;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.stone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: deleting ? null : onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: ColoredBox(
                        color: AppColors.ember,
                        child: _DesignThumbnail(design: design),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    design.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall,
                  ),
                  Text(
                    design.garmentType,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: deleting
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                        if (value == 'publish') onPublish();
                        if (value == 'unpublish') onUnpublish();
                      },
                      itemBuilder: (context) => [
                        if (!design.isPublic)
                          const PopupMenuItem<String>(
                            value: 'publish',
                            child: Text('Publish to Showcase'),
                          ),
                        if (design.isPublic)
                          const PopupMenuItem<String>(
                            value: 'unpublish',
                            child: Text('Unpublish'),
                          ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
            ),
            if (deleting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66FFFFFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Prefer AI look, compose capture, flat-lay, or catalogue asset for the tile.
class _DesignThumbnail extends ConsumerWidget {
  const _DesignThumbnail({required this.design});

  final GarmentDesign design;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmsLookup = ref.watch(designCatalogLookupProvider);
    final preview = designPreviewImageSource(
      design,
      cmsLookup: cmsLookup,
    );
    final fit = preview?.contain == true ? BoxFit.contain : BoxFit.cover;

    if (preview != null) {
      final source = preview.source;
      final image = source.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: source,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => _ThumbnailPlaceholder(
                primaryColour: design.primaryColour,
              ),
            )
          : CatalogImage(
              path: source,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.bottomCenter,
              errorWidget: _ThumbnailPlaceholder(
                primaryColour: design.primaryColour,
              ),
            );
      if (preview.contain) {
        return ColoredBox(
          color: Colors.white,
          child: image,
        );
      }
      return image;
    }

    return _ThumbnailPlaceholder(primaryColour: design.primaryColour);
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({required this.primaryColour});

  final String primaryColour;

  @override
  Widget build(BuildContext context) {
    final tint = parseAiColour(primaryColour, fallback: AppColors.teal);
    return ColoredBox(
      color: tint.withValues(alpha: 0.35),
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: tint,
          size: 32,
        ),
      ),
    );
  }
}
