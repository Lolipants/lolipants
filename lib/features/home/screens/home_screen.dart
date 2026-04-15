import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/home/widgets/category_pills.dart';
import 'package:lolipants/features/home/widgets/hero_banner.dart';
import 'package:lolipants/features/home/widgets/home_header.dart';
import 'package:lolipants/features/home/widgets/style_grid.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Authenticated home feed: greeting, hero, categories, and style grid.
class HomeScreen extends ConsumerWidget {
  /// Creates the home tab screen.
  const HomeScreen({super.key});

  Future<void> _openAiPrompt(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
        ),
        child: const AiPromptBar(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const HomeHeader(),
                      HeroBanner(onTryNow: () => _openAiPrompt(context)),
                      const SizedBox(height: AppSpacing.lg),
                      const CategoryPills(),
                      const SizedBox(height: AppSpacing.xl),
                      const StyleGrid(),
                    ]),
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
