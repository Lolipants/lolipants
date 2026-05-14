import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/data/bundled_design_assets.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
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
                        onTap: () => _openDesign(design),
                        onLongPress: () => _confirmDelete(design),
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
    required this.onLongPress,
  });

  final GarmentDesign design;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
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
      ),
    );
  }
}

/// Prefer remote print/sketch URLs, then bundled flat from [GarmentDesign.renderMetadata].
class _DesignThumbnail extends StatelessWidget {
  const _DesignThumbnail({required this.design});

  final GarmentDesign design;

  static String? _firstHttpUrl(String? a, String? b) {
    for (final u in [a, b]) {
      final s = u?.trim();
      if (s != null && s.isNotEmpty && s.startsWith('http')) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final remote = _firstHttpUrl(design.printImageUrl, design.sketchImageUrl);
    if (remote != null) {
      return CachedNetworkImage(
        imageUrl: remote,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => const _ThumbnailPlaceholder(),
      );
    }

    final assetPath =
        catalogDesignAssetFromRenderMetadata(design.renderMetadata);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
      );
    }

    return const _ThumbnailPlaceholder();
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.design_services_outlined,
        color: AppColors.gold,
      ),
    );
  }
}
