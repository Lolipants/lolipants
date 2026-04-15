import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/browse/providers/mannequins_providers.dart';
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

  String _selectedId = 'standard_male';
  MannequinOption? _generatedMannequin;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final mannequinsState = ref.watch(mannequinOptionsProvider);
    final apiMannequins = mannequinsState.valueOrNull ?? const <MannequinOption>[];
    final mannequins = [
      ...(apiMannequins.isEmpty ? _fallbackItems : apiMannequins),
      if (_generatedMannequin != null) _generatedMannequin!,
    ];

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
                    SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: mannequins.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index == mannequins.length) {
                            final selected = _selectedId == 'custom_photo';
                            return _MannequinCard(
                              selected: selected,
                              english: 'Use my photo',
                              arabic: 'استخدم صورتي',
                              onTap: () => _handleCustomPhoto(context),
                              child: const Icon(
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
                            onTap: () => setState(() => _selectedId = item.id),
                            child: MiniMannequin(
                              primaryColour: editor.primaryColour,
                              accentColour: editor.accentColour,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: LolipantsButton(
                  label: AppStrings.startDesigningCta,
                  onPressed: () {
                    ref.read(editorProvider.notifier).setMannequin(_selectedId);
                    context.push('/editor', extra: _selectedId);
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
    final result = await repo.generateFromPhoto(photoPath: picked.path);
    if (!mounted) return;
    result.fold(
      (e) {
        final message = switch (e) {
          NetworkException(message: final m) => m,
          AuthException(message: final m) => m,
          ServerException(message: final m) => m,
          UnknownException() => 'Unknown error',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate mannequin: $message')),
        );
      },
      (generated) {
        ref.read(editorProvider.notifier).setCustomMannequinImagePath(picked.path);
        setState(() {
          if (generated.id.isNotEmpty) {
            _generatedMannequin = generated;
            _selectedId = generated.id;
          } else {
            _selectedId = 'custom_photo';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('3D mannequin generated successfully.')),
        );
      },
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
