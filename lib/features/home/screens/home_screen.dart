import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/ai/ai_data_sharing_consent.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/home/logic/ensure_design_gender.dart';
import 'package:lolipants/features/home/widgets/hero_banner.dart';
import 'package:lolipants/features/home/widgets/home_design_flow.dart';
import 'package:lolipants/features/home/widgets/home_header.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Authenticated home: greeting, guided design flow, AI hero.
class HomeScreen extends ConsumerWidget {
  /// Creates the home tab screen.
  const HomeScreen({super.key});

  Future<void> _openAiPrompt(BuildContext context, WidgetRef ref) async {
    final allowed = await AiDataSharingConsent.ensure(context, ref);
    if (!allowed || !context.mounted) return;

    final gender = await ensureDesignGender(context, ref);
    if (gender == null || !context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AiPromptBar(initialGender: gender),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ArabesqueBackground(opacity: 0.14),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: HomeHeader(),
                ),
                const Expanded(child: HomeDesignFlow()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: HeroBanner(
                    onTryNow: () => _openAiPrompt(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
