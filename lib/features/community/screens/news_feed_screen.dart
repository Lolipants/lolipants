import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/post_card.dart';
import 'package:lolipants/features/community/widgets/showcase_feed_slivers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/lolipants_button.dart';

/// Available tag filters on the feed.
const _feedTags = <String, String>{
  'all': 'All',
  'abaya': 'Abaya',
  'thobe': 'Thobe',
  'suit': 'Suit',
  'dress': 'Dress',
  'showcase': 'Showcase',
};

/// Main news feed screen: filter chips, pull-to-refresh, infinite scroll.
class NewsFeedScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const NewsFeedScreen({super.key});

  @override
  ConsumerState<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends ConsumerState<NewsFeedScreen> {
  final _scrollController = ScrollController();
  String _activeTag = 'all';

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

  String? get _tagFilter => _activeTag == 'all' ? null : _activeTag;

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.offset >= threshold) {
      ref.read(feedPostsProvider(_tagFilter).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedPostsProvider(_tagFilter));
    final notifier = ref.read(feedPostsProvider(_tagFilter).notifier);

    return Scaffold(
      backgroundColor: AppColors.ink,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Semantics(
            label: 'Design button',
            button: true,
            child: FloatingActionButton(
              heroTag: 'design_community_feed',
              elevation: 2,
              focusElevation: 4,
              hoverElevation: 4,
              highlightElevation: 6,
              onPressed: () => context.push('/mannequin-selector'),
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
              child: const Icon(Icons.design_services_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Create post',
            button: true,
            child: FloatingActionButton.extended(
              heroTag: 'create-post',
              elevation: 2,
              focusElevation: 4,
              hoverElevation: 4,
              highlightElevation: 6,
              onPressed: () async {
                final created = await context.push<bool>('/community/new-post');
                if (created == true) {
                  for (final tag in kNewsFeedTagFilterKeys) {
                    ref.invalidate(feedPostsProvider(tag));
                  }
                }
              },
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.add),
              label: const Text('Post'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              children: [
                _FilterChips(
                  active: _activeTag,
                  onSelect: (tag) => setState(() => _activeTag = tag),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.ink,
                    onRefresh: () async {
                      await Future.wait([
                        notifier.refresh(),
                        ref.read(showcaseFeedProvider.notifier).refresh(),
                      ]);
                    },
                    child: _FeedBody(
                      state: state,
                      controller: _scrollController,
                      tagFilter: _tagFilter,
                      onToggleReaction: (post, reaction) =>
                          notifier.toggleReaction(post.id, reaction),
                      onOpenDetail: (post) => context.push(
                        '/community/posts/${post.id}',
                        extra: post,
                      ),
                      onTapAuthor: (post) =>
                          context.push('/community/designer/${post.authorId}'),
                    ),
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onSelect});

  final String active;
  final ValueChanged<String> onSelect;

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
        children: _feedTags.entries
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

class _FeedBody extends ConsumerWidget {
  const _FeedBody({
    required this.state,
    required this.controller,
    required this.tagFilter,
    required this.onToggleReaction,
    required this.onOpenDetail,
    required this.onTapAuthor,
  });

  final FeedPostsState state;
  final ScrollController controller;
  final String? tagFilter;
  final void Function(Post, ReactionType) onToggleReaction;
  final ValueChanged<Post> onOpenDetail;
  final ValueChanged<Post> onTapAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showcaseState = ref.watch(showcaseFeedProvider);
    final showcaseSlivers = buildShowcaseFeedSlivers(
      tagFilter: tagFilter,
      showcaseItems: showcaseState.items,
    );
    final hasShowcase = showcaseSlivers.isNotEmpty;

    if (state.loading &&
        state.posts.isEmpty &&
        showcaseState.loading &&
        !hasShowcase) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (state.error != null && state.posts.isEmpty && !hasShowcase) {
      final message = communityErrorMessage(
        state.error!,
        fallback: 'Could not load community feed.',
      );
      return _ErrorRetry(
        message: message,
        onRetry: () =>
            ref.read(feedPostsProvider(tagFilter).notifier).loadFirstPage(),
      );
    }
    if (state.posts.isEmpty && !hasShowcase) {
      return ListView(
        controller: controller,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: AppColors.gold,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Be the first to post',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share a design, ask for feedback, or highlight a trend.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: controller,
      slivers: [
        ...showcaseSlivers,
        if (tagFilter == 'showcase' && state.posts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Text(
                'Showcase posts',
                style: AppTextStyles.titleSmall,
              ),
            ),
          ),
        if (state.posts.isEmpty && hasShowcase)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No posts yet for this filter.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 168),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = state.posts[index];
                return PostCard(
                  post: post,
                  onToggleReaction: (r) => onToggleReaction(post, r),
                  onOpenDetail: () => onOpenDetail(post),
                  onTapAuthor: () => onTapAuthor(post),
                );
              },
              childCount: state.posts.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _FeedFooter(state: state),
        ),
      ],
    );
  }
}

class _FeedFooter extends StatelessWidget {
  const _FeedFooter({required this.state});

  final FeedPostsState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }
    if (state.reachedEnd && state.posts.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Thats all the posts for now.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.rubyLight,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                LolipantsButton(
                  label: 'Retry',
                  onPressed: onRetry,
                  variant: LolipantsButtonVariant.secondary,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
