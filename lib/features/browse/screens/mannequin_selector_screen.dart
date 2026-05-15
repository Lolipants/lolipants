import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Selects mannequin shape before opening the editor.
class MannequinSelectorScreen extends ConsumerStatefulWidget {
  /// Creates the mannequin picker screen.
  const MannequinSelectorScreen({super.key});

  @override
  ConsumerState<MannequinSelectorScreen> createState() =>
      _MannequinSelectorScreenState();
}

class _MannequinSelectorScreenState
    extends ConsumerState<MannequinSelectorScreen> {
  /// One tile per bundled mannequin PNG; ids match [kBuiltInMannequinAssets].
  static const _bundledMannequins = <MannequinOption>[
    MannequinOption(
      id: 'petite_female',
      labelEn: 'Petite (Female)',
      labelAr: 'نسائي قصير',
    ),
    MannequinOption(
      id: 'standard_female',
      labelEn: 'Standard (Female)',
      labelAr: 'نسائي قياسي',
    ),
    MannequinOption(
      id: 'athletic_female',
      labelEn: 'Athletic (Female)',
      labelAr: 'نسائي رياضي',
    ),
    MannequinOption(
      id: 'curvy_female',
      labelEn: 'Curvy (Female)',
      labelAr: 'نسائي ممتلئ',
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
  ];

  late String _selectedId;
  String? _customPhotoPath;

  Future<void> _pickPhoto() async {
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
    final picked = await picker.pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    setState(() {
      _customPhotoPath = picked.path;
      _selectedId = 'custom_photo';
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedId = kFeatureMens ? 'standard_male' : 'standard_female';
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    const mannequins = _bundledMannequins;
    if (!mannequins.any((m) => m.id == _selectedId)) {
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 190,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: mannequins.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final item = mannequins[index];
                              final selected = _selectedId == item.id;
                              return _MannequinCard(
                                selected: selected,
                                english: item.labelEn,
                                arabic: item.labelAr,
                                onTap: () => setState(() {
                                  _selectedId = item.id;
                                  _customPhotoPath = null;
                                }),
                                child: () {
                                  final builtIn =
                                      builtInMannequinAssetPath(item.id);
                                  if (builtIn != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      child: ColoredBox(
                                        color: const Color(0xFFE8E4EA),
                                        child: Image.asset(
                                          builtIn,
                                          width: 88,
                                          height: 110,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              MiniMannequin(
                                            primaryColour:
                                                editor.primaryColour,
                                            accentColour: editor.accentColour,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return MiniMannequin(
                                    primaryColour: editor.primaryColour,
                                    accentColour: editor.accentColour,
                                  );
                                }(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text(
                            'Upload your photo (AI body reference)',
                          ),
                        ),
                        if (_customPhotoPath != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Custom photo selected — used for AI output.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ],
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
                    context.push(
                      '/editor',
                      extra: EditorBootstrapArgs(
                        mannequinId: _selectedId,
                        customMannequinImagePath: _customPhotoPath,
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
