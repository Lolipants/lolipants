import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/editor/providers/designs_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/loading_overlay.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/shared/widgets/lolipants_text_field.dart';

/// Lists saved user designs from the backend.
class MyDesignsScreen extends ConsumerStatefulWidget {
  /// Creates my-designs screen.
  const MyDesignsScreen({super.key});

  @override
  ConsumerState<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends ConsumerState<MyDesignsScreen> {
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final designsState = ref.watch(myDesignsProvider);
    final designs = designsState.valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myDesigns)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : () => _openCreateDesignSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Save draft'),
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
                    padding: const EdgeInsets.all(AppSpacing.xl),
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
                      return Container(
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.ember,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.design_services_outlined,
                                  color: AppColors.gold,
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
                      );
                    },
                  ),
          ),
          LoadingOverlay(visible: designsState.isLoading && designs.isNotEmpty),
        ],
      ),
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
              Text('Save design draft', style: AppTextStyles.titleMedium),
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
                label: 'Save',
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
