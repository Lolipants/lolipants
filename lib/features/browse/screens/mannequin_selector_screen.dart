import 'dart:ui' show Locale;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/config/app_features.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_strings.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/preferences/design_gender_defaults.dart';
import 'package:lolipants/core/preferences/user_gender_provider.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';
import 'package:lolipants/features/editor/data/built_in_mannequin_assets.dart';
import 'package:lolipants/features/browse/logic/region_preset_editor.dart';
import 'package:lolipants/features/editor/models/editor_preset_args.dart';
import 'package:lolipants/features/home/models/home_flow_selection.dart';
import 'package:lolipants/features/wedding/models/wedding_flow_args.dart';
import 'package:lolipants/features/home/providers/home_flow_provider.dart';
import 'package:lolipants/features/editor/providers/editor_provider.dart';
import 'package:lolipants/features/editor/widgets/bundled_mannequin_image.dart';
import 'package:lolipants/features/editor/widgets/mannequin_viewer.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Selects mannequin shape before opening the editor.
class MannequinSelectorScreen extends ConsumerStatefulWidget {
  /// Creates the mannequin picker screen.
  const MannequinSelectorScreen({this.pendingPreset, this.homeFlow, super.key});

  /// Catalogue design to open after mannequin selection (from home/browse).
  final EditorPresetArgs? pendingPreset;

  /// Home wizard selections when opened from the guided home flow.
  final HomeFlowSelection? homeFlow;

  @override
  ConsumerState<MannequinSelectorScreen> createState() =>
      _MannequinSelectorScreenState();
}

class _MannequinSelectorScreenState
    extends ConsumerState<MannequinSelectorScreen> {
  static final _bundledMannequins = kVersionMannequinCatalog
      .map(
        (m) => MannequinOption(
          id: m.id,
          labelEn: m.labelEn,
          labelAr: m.labelAr,
        ),
      )
      .toList(growable: false);

  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = kPresetCatalogMannequinId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyGenderDefaults());
  }

  void _applyGenderDefaults() {
    if (!mounted) return;
    final gender = ref.read(userGenderProvider);
    final ordered = sortMannequinsForGender(_bundledMannequins, gender);
    final preferred = gender != null
        ? mannequinIdForGender(gender)
        : (kFeatureMens ? 'standard_male' : kPresetCatalogMannequinId);
    final id = ordered.any((m) => m.id == preferred)
        ? preferred
        : ordered.first.id;
    if (_selectedId != id) {
      setState(() => _selectedId = id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsLocaleProvider);
    final editor = ref.watch(editorProvider);
    final gender = ref.watch(userGenderProvider);
    final mannequins = sortMannequinsForGender(_bundledMannequins, gender);
    if (!mannequins.any((m) => m.id == _selectedId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedId = mannequins.first.id);
        }
      });
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.homeFlow != null) {
          ref.read(homeFlowSelectionProvider.notifier).resetToStart();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          localizedFromLocale(
            locale,
            AppStrings.chooseMannequinEn,
            AppStrings.chooseMannequinAr,
          ),
        ),
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
                                locale: locale,
                                selected: selected,
                                english: item.labelEn,
                                arabic: item.labelAr,
                                onTap: () => setState(() => _selectedId = item.id),
                                child: () {
                                  final builtIn =
                                      builtInMannequinAssetPath(item.id);
                                  if (builtIn != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      child: SizedBox.expand(
                                        child: BundledMannequinImage(
                                          assetPath: builtIn,
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
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: LolipantsButton(
                  label: localizedFromLocale(
                    locale,
                    AppStrings.homeFlowStartDesigning,
                    AppStrings.homeFlowStartDesigningAr,
                  ),
                  onPressed: () {
                    final pending = widget.pendingPreset;
                    final homeFlow = widget.homeFlow;
                    if (homeFlow != null &&
                        homeFlow.isComplete &&
                        homeFlow.style == HomeStyleLane.wedding &&
                        homeFlow.weddingFulfillment != null &&
                        kFeatureWeddingFlow) {
                      context.push(
                        '/wedding/dresses',
                        extra: WeddingFlowArgs(
                          fulfillment: homeFlow.weddingFulfillment,
                          mannequinId: _selectedId,
                        ),
                      );
                      return;
                    }
                    final preset = pending != null
                        ? editorPresetWithMannequin(pending, _selectedId)
                        : null;
                    final source = homeFlow != null && homeFlow.isComplete
                        ? 'home_flow'
                        : preset != null
                            ? 'browse_design'
                            : 'mannequin_selector';
                    context.push(
                      '/editor',
                      extra: EditorBootstrapArgs(
                        mannequinId: _selectedId,
                        preset: preset,
                        source: source,
                        homeFlow: homeFlow,
                        initialTab: _initialTabForFlow(homeFlow),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

String? _initialTabForFlow(HomeFlowSelection? flow) {
  if (flow == null || !flow.isComplete) return null;
  return 'build';
}

class _MannequinCard extends StatelessWidget {
  const _MannequinCard({
    required this.locale,
    required this.selected,
    required this.english,
    required this.arabic,
    required this.onTap,
    required this.child,
  });

  final Locale locale;
  final bool selected;
  final String english;
  final String arabic;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = localizedFromLocale(
      locale,
      english,
      arabic.isNotEmpty ? arabic : english,
    );
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: child,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.gold : AppColors.dust,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
