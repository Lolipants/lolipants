import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/ai/ai_data_sharing_consent.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/features/editor/widgets/ai_prompt_bar.dart';
import 'package:lolipants/features/home/logic/ensure_design_gender.dart';
import 'package:lolipants/features/home/widgets/hero_banner.dart';
import 'package:lolipants/features/home/widgets/home_design_flow.dart';
import 'package:lolipants/features/home/widgets/home_featured_section.dart';
import 'package:lolipants/features/home/widgets/home_header.dart';
import 'package:lolipants/features/home/widgets/home_scroll_hint.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Authenticated home: greeting, guided design flow, AI hero, featured designs.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the home tab screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  var _showScrollHint = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScrollHintWithContent();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_showScrollHint) return;
    if (_scrollController.hasClients && _scrollController.offset > 16) {
      setState(() => _showScrollHint = false);
    }
  }

  void _syncScrollHintWithContent() {
    if (!mounted || !_scrollController.hasClients) return;
    final canScroll = _scrollController.position.maxScrollExtent > 8;
    if (!canScroll && _showScrollHint) {
      setState(() => _showScrollHint = false);
    }
  }

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

  double _wizardHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final available = size.height - padding.top - padding.bottom - 72;
    return available.clamp(300.0, 480.0);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ArabesqueBackground(opacity: 0.14),
          SafeArea(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  _syncScrollHintWithContent();
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      child: const HomeHeader(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: _wizardHeight(context),
                      child: const HomeDesignFlow(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: HeroBanner(
                        onTryNow: () => _openAiPrompt(context, ref),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: HomeFeaturedSection(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showScrollHint ? 1 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: HomeScrollHint(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
