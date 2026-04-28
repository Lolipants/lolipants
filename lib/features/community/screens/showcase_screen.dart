import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/data/showcase_repository.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/showcase_card.dart';
import 'package:lolipants/features/orders/models/order_design_draft.dart';
import 'package:lolipants/features/orders/providers/checkout_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Marketplace grid showing public designs with trending/new/most-ordered sort.
class ShowcaseScreen extends ConsumerStatefulWidget {
  /// Creates the showcase screen.
  const ShowcaseScreen({super.key});

  @override
  ConsumerState<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends ConsumerState<ShowcaseScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent - 240) {
      ref.read(showcaseFeedProvider.notifier).loadMore();
    }
  }

  void _orderShowcaseItem(ShowcaseItem item) {
    final design = OrderDesignDraft(
      designId: item.designId,
      name: item.name,
      garmentType: item.garmentType,
      primaryColour: item.primaryColour,
      accentColour: item.accentColour,
      designerId: item.designer.id,
      designerName: item.designer.name,
    );
    startCheckoutDraft(ref, design);
    context.push('/order/summary', extra: design);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showcaseFeedProvider);
    final activeSort = ref.watch(showcaseSortProvider);
    final notifier = ref.read(showcaseFeedProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Showcase', style: AppTextStyles.titleLarge),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              children: [
                _SortChips(
                  active: activeSort,
                  onSelect: (sort) => ref
                      .read(showcaseSortProvider.notifier)
                      .state = sort,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.ink,
                    onRefresh: notifier.refresh,
                    child: _buildBody(state),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ShowcaseFeedState state) {
    if (state.loading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      final message = communityErrorMessage(
        state.error!,
        fallback: 'Could not load showcase.',
      );
      return ListView(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  LolipantsButton(
                    label: 'Retry',
                    fullWidth: false,
                    variant: LolipantsButtonVariant.secondary,
                    onPressed: () => ref
                        .read(showcaseFeedProvider.notifier)
                        .loadFirstPage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'No showcase designs yet. Be the first to publish.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      );
    }
    final crossCount = MediaQuery.sizeOf(context).width >= 800 ? 3 : 2;
    final listCount = state.items.length + 1;
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.62,
      ),
      itemCount: listCount,
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          if (state.loadingMore) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          return const SizedBox.shrink();
        }
        final item = state.items[index];
        return ShowcaseCard(
          item: item,
          onTap: () =>
              context.push('/community/designer/${item.designer.id}'),
          onOrder: () => _orderShowcaseItem(item),
        );
      },
    );
  }
}

class _SortChips extends StatelessWidget {
  const _SortChips({required this.active, required this.onSelect});

  final ShowcaseSort active;
  final ValueChanged<ShowcaseSort> onSelect;

  static const _entries = <ShowcaseSort, String>{
    ShowcaseSort.trending: 'Trending',
    ShowcaseSort.newest: 'Newest',
    ShowcaseSort.mostOrdered: 'Most ordered',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 6,
        ),
        children: _entries.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: _Chip(
                  label: entry.value,
                  active: entry.key == active,
                  onTap: () => onSelect(entry.key),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.ember,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.gold : AppColors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.titleSmall.copyWith(
            color: active ? AppColors.ink : AppColors.sand,
          ),
        ),
      ),
    );
  }
}
