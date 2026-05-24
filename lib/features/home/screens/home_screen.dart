import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/home/logic/ensure_design_gender.dart';
import 'package:lolipants/features/home/widgets/hero_banner.dart';
import 'package:lolipants/features/home/widgets/home_category_shortcuts.dart';
import 'package:lolipants/features/home/widgets/home_header.dart';
import 'package:lolipants/features/home/widgets/style_grid.dart';

/// Authenticated home: greeting, AI hero, category shortcuts, featured grid.
class HomeScreen extends ConsumerWidget {
  /// Creates the home tab screen.
  const HomeScreen({super.key});

  Future<void> _openAiPrompt(BuildContext context, WidgetRef ref) async {
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeader(),
              HeroBanner(onTryNow: () => _openAiPrompt(context, ref)),
              const SizedBox(height: AppSpacing.lg),
              const HomeCategoryShortcuts(),
              const SizedBox(height: AppSpacing.lg),
              const Expanded(
                child: StyleGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
