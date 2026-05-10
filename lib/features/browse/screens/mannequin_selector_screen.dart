import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/browse/data/mannequins_repository.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/browse/providers/mannequins_providers.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Selects mannequin shape before opening the editor.
class MannequinSelectorScreen extends ConsumerStatefulWidget {
  const MannequinSelectorScreen({super.key});

  @override
  ConsumerState<MannequinSelectorScreen> createState() =>
      _MannequinSelectorScreenState();
}

class _MannequinSelectorScreenState
    extends ConsumerState<MannequinSelectorScreen> {
  static const _fallbackItems = <MannequinOption>[
    MannequinOption(
      id: 'standard_female',
      labelEn: 'Standard (Female)',
      labelAr: 'نسائي قياسي',
    ),
    MannequinOption(
      id: 'curvy_female',
      labelEn: 'Curvy (Female)',
      labelAr: 'نسائي ممتلئ',
    ),
    MannequinOption(
      id: 'petite_female',
      labelEn: 'Petite (Female)',
      labelAr: 'نسائي قصير',
    ),
    MannequinOption(
      id: 'athletic_female',
      labelEn: 'Athletic (Female)',
      labelAr: 'نسائي رياضي',
    ),
    MannequinOption(
      id: 'plus_female',
      labelEn: 'Plus (Female)',
      labelAr: 'نسائي بلس',
    ),
    MannequinOption(
      id: 'standard_male',
      labelEn: 'Standard (Male)',
      labelAr: 'رجالي قياسي',
    ),
    MannequinOption(
      id: 'tall_male',
      labelEn: 'Tall (Male)',
      labelAr: 'رجالي طويل',
    ),
    MannequinOption(
      id: 'child',
      labelEn: 'Child',
      labelAr: 'أطفال',
    ),
  ];

  late String _selectedId;
  MannequinOption? _generatedMannequin;
  bool _isGenerating = false;
  String? _generationStatus;
  String? _pendingJobId;

  @override
  void initState() {
    super.initState();
    _selectedId = kFeatureMens ? 'standard_male' : 'standard_female';
  }

  List<MannequinOption> _mannequinsList(List<MannequinOption> raw) {
    if (kFeatureMens) return raw;
    return raw.where((o) {
      if (isMaleMannequinOption(o)) return false;
      final id = o.id.toLowerCase();
      final en = o.labelEn.toLowerCase();
      final ar = o.labelAr;
      if (id.contains('child') || id.contains('kid')) return false;
      if (en.contains('child') || en.contains('kid')) return false;
      if (ar.contains('أطفال') || ar.contains('طفل')) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final mannequinsState = ref.watch(mannequinOptionsProvider);
    final apiMannequins = mannequinsState.valueOrNull;
    var mannequins = [
      ...((apiMannequins == null || apiMannequins.isEmpty)
          ? _fallbackItems
          : apiMannequins),
      if (_generatedMannequin != null) _generatedMannequin!,
    ];
    mannequins = _mannequinsList(mannequins);
    if (mannequins.isNotEmpty && !mannequins.any((m) => m.id == _selectedId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedId = mannequins.first.id);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chooseMannequin),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    if (mannequinsState.isLoading)
                      const _SelectorSkeletonRow()
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mannequinsState.hasError) ...[
                            _SelectorErrorState(
                              onRetry: () =>
                                  ref.invalidate(mannequinOptionsProvider),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          SizedBox(
                            height: 190,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  mannequins.length +
                                  (kFeatureCustomPhotoMannequin ? 1 : 0),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                if (kFeatureCustomPhotoMannequin &&
                                    index == mannequins.length) {
                                  final selected =
                                      _selectedId == 'custom_photo';
                                  return _MannequinCard(
                                    selected: selected,
                                    english: _isGenerating
                                        ? 'Generating 3D...'
                                        : 'Use my photo',
                                    arabic: _isGenerating
                                        ? 'جاري إنشاء ثلاثي الأبعاد...'
                                        : 'استخدم صورتي',
                                    onTap: _isGenerating
                                        ? () {}
                                        : () => _handleCustomPhoto(context),
                                    child: _isGenerating
                                        ? const CircularProgressIndicator(
                                            color: AppColors.gold,
                                          )
                                        : const Icon(
                                            Icons.add_a_photo_outlined,
                                            color: AppColors.gold,
                                            size: 36,
                                          ),
                                  );
                                }
                                final item = mannequins[index];
                                final selected = _selectedId == item.id;
                                return _MannequinCard(
                                  selected: selected,
                                  english: item.labelEn,
                                  arabic: item.labelAr,
                                  onTap: () =>
                                      setState(() => _selectedId = item.id),
                                  child: item.previewUrl != null &&
                                          item.previewUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.sm,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: item.previewUrl!,
                                            width: 88,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                MiniMannequin(
                                              primaryColour:
                                                  editor.primaryColour,
                                              accentColour: editor.accentColour,
                                            ),
                                          ),
                                        )
                                      : MiniMannequin(
                                          primaryColour: editor.primaryColour,
                                          accentColour: editor.accentColour,
                                        ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    if (kFeatureCustomPhotoMannequin &&
                        _generationStatus != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _generationStatus!,
                        style: AppTextStyles.bodySmall,
                      ),
                      if (_pendingJobId != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: _isGenerating
                              ? null
                              : () => _resumePendingGeneration(),
                          child: const Text('Check render status again'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: LolipantsButton(
                  label: AppStrings.startDesigningCta,
                  onPressed: () {
                    ref.read(editorProvider.notifier).setMannequin(_selectedId);
                    context.push(
                      '/editor',
                      extra: EditorBootstrapArgs(
                        mannequinId: _selectedId,
                        source: 'mannequin_selector',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCustomPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 92);
    if (picked == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.stone,
        title: const Text('Use this photo for 3D mannequin?'),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.file(
            File(picked.path),
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(height: 180),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final repo = ref.read(mannequinsRepositoryProvider);
    setState(() {
      _isGenerating = true;
      _generationStatus = 'Starting mannequin generation...';
    });
    final start = await repo.startGeneration(photoPath: picked.path);
    if (!mounted) return;
    await start.fold(
      (e) {
        setState(() {
          _isGenerating = false;
          _generationStatus = null;
        });
        final message = switch (e) {
          NetworkException(message: final m) => m,
          AuthException(message: final m) => m,
          ServerException(message: final m) => m,
          UnknownException() => 'Unknown error',
        };
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate mannequin: $message')),
        );
      },
      (startResult) async {
        final resolved = await _pollForGeneratedMannequin(
          repo,
          jobId: startResult.jobId,
        );
        if (!mounted) return;
        if (resolved == null) {
          setState(() {
            _isGenerating = false;
            _generationStatus = 'Generation still running. You can continue polling.';
            _pendingJobId = startResult.jobId;
            _selectedId = 'custom_photo';
          });
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('3D mannequin generation is still running.'),
            ),
          );
          return;
        }

        ref
            .read(editorProvider.notifier)
            .setCustomMannequinImagePath(picked.path);
        setState(() {
          _isGenerating = false;
          _generationStatus = null;
          _pendingJobId = null;
          _generatedMannequin = resolved;
          _selectedId = resolved.id;
        });
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('3D mannequin generated successfully.')),
        );
      },
    );
  }

  Future<void> _resumePendingGeneration() async {
    final jobId = _pendingJobId;
    if (jobId == null || jobId.isEmpty) return;
    final repo = ref.read(mannequinsRepositoryProvider);
    setState(() {
      _isGenerating = true;
      _generationStatus = 'Checking generation status...';
    });
    final resolved = await _pollForGeneratedMannequin(repo, jobId: jobId);
    if (!mounted) return;
    if (resolved == null) {
      setState(() {
        _isGenerating = false;
        _generationStatus = 'Still rendering. Please check again shortly.';
      });
      return;
    }
    setState(() {
      _isGenerating = false;
      _generationStatus = null;
      _pendingJobId = null;
      _generatedMannequin = resolved;
      _selectedId = resolved.id;
    });
  }

  Future<MannequinOption?> _pollForGeneratedMannequin(
    MannequinsRepository repo, {
    required String jobId,
  }) async {
    if (jobId.isEmpty) return null;
    for (var i = 0; i < 8; i++) {
      if (!mounted) return null;
      setState(() {
        _generationStatus = 'Generating 3D mannequin... (${i + 1}/8)';
      });
      final result = await repo.getGenerationStatus(jobId: jobId);
      if (!mounted) return null;
      final done = result.fold<MannequinOption?>((_) => null, (status) {
        if (status.status == 'completed' && status.mannequin != null) {
          return status.mannequin;
        }
        return null;
      });
      if (done != null) return done;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }
}

class _SelectorSkeletonRow extends StatelessWidget {
  const _SelectorSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => Container(
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.stone,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSubtle),
          ),
        ),
      ),
    );
  }
}

class _SelectorErrorState extends StatelessWidget {
  const _SelectorErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.rubyLight),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Could not load mannequin options from server.'),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _MannequinCard extends StatelessWidget {
  const _MannequinCard({
    required this.selected,
    required this.english,
    required this.arabic,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String english;
  final String arabic;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.stone,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.borderStrong : AppColors.borderDefault,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: Center(child: child)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              english,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.gold : AppColors.dust,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              arabic,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.gold : AppColors.fog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
