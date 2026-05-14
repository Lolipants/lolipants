import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/community/data/complaints_repository.dart';
import 'package:lolipants/features/community/data/community_repository.dart';
import 'package:lolipants/features/community/data/designers_repository.dart';
import 'package:lolipants/features/community/data/media_upload_repository.dart';
import 'package:lolipants/features/community/data/posts_repository.dart';
import 'package:lolipants/features/community/data/showcase_repository.dart';
import 'package:lolipants/features/community/models/comment.dart';
import 'package:lolipants/features/community/models/commission.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// Selected tab inside [CommunityScreen] (`0` = Feed). Used by [MainShell] to
/// avoid duplicate FABs with the global Design CTA.
final communityHubTabIndexProvider = StateProvider<int>((ref) => 0);

/// Consultation repository (posts are in the dedicated posts provider below).
final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Posts + reactions + comments repository.
final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => PostsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// User-submitted moderation complaints.
final complaintsRepositoryProvider = Provider<ComplaintsRepository>(
  (ref) => ComplaintsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Designer/follow/commission repository.
final designersRepositoryProvider = Provider<DesignersRepository>(
  (ref) => DesignersRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Showcase repository.
final showcaseRepositoryProvider = Provider<ShowcaseRepository>(
  (ref) => ShowcaseRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Shared media upload helper (image attachment, editor share).
final mediaUploadRepositoryProvider = Provider<MediaUploadRepository>(
  (ref) => MediaUploadRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Paginated feed state backed by [PostsRepository].
class FeedPostsState {
  /// Creates a feed state.
  const FeedPostsState({
    this.posts = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.hasInitialised = false,
  });

  /// Posts currently loaded.
  final List<Post> posts;

  /// True while the first page is loading.
  final bool loading;

  /// True while an additional page is loading.
  final bool loadingMore;

  /// Latest error for the first load.
  final Object? error;

  /// Next cursor or null if we reached the end.
  final String? nextCursor;

  /// True once the first load attempt completed.
  final bool hasInitialised;

  /// True once we know there are no more pages.
  bool get reachedEnd => hasInitialised && (nextCursor == null);

  /// Clone helper.
  FeedPostsState copyWith({
    List<Post>? posts,
    bool? loading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasInitialised,
  }) {
    return FeedPostsState(
      posts: posts ?? this.posts,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : error ?? this.error,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
      hasInitialised: hasInitialised ?? this.hasInitialised,
    );
  }
}

/// Feed posts provider, keyed by optional tag filter.
final feedPostsProvider =
    StateNotifierProvider.family<FeedPostsNotifier, FeedPostsState, String?>(
  (ref, tag) => FeedPostsNotifier(ref: ref, tag: tag)..loadFirstPage(),
);

/// Tag keys used by [NewsFeedScreen] filters (`all` → null).
const kNewsFeedTagFilterKeys = <String?>[
  null,
  'abaya',
  'thobe',
  'suit',
  'dress',
  'showcase',
];

/// StateNotifier driving paginated feed with optimistic reaction toggles.
class FeedPostsNotifier extends StateNotifier<FeedPostsState> {
  /// Creates the notifier.
  FeedPostsNotifier({required Ref ref, this.tag})
      : _ref = ref,
        super(const FeedPostsState());

  final Ref _ref;

  /// Optional tag filter.
  final String? tag;

  /// Loads the first page, resetting any previously loaded content.
  Future<void> loadFirstPage() async {
    state = state.copyWith(loading: true, clearError: true);
    final repo = _ref.read(postsRepositoryProvider);
    final result = await repo.getFeed(tag: tag);
    state = result.fold<FeedPostsState>(
      (e) => state.copyWith(
        loading: false,
        error: e,
        hasInitialised: true,
      ),
      (page) => FeedPostsState(
        posts: page.posts,
        loading: false,
        loadingMore: false,
        nextCursor: page.nextCursor,
        hasInitialised: true,
      ),
    );
  }

  /// Pull-to-refresh: re-loads first page while keeping old posts visible.
  Future<void> refresh() async {
    final repo = _ref.read(postsRepositoryProvider);
    final result = await repo.getFeed(tag: tag);
    state = result.fold<FeedPostsState>(
      (e) => state.copyWith(error: e),
      (page) => FeedPostsState(
        posts: page.posts,
        loading: false,
        loadingMore: false,
        nextCursor: page.nextCursor,
        hasInitialised: true,
      ),
    );
  }

  /// Appends the next page if one exists.
  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || state.reachedEnd) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    final repo = _ref.read(postsRepositoryProvider);
    final result = await repo.getFeed(tag: tag, cursor: cursor);
    state = result.fold<FeedPostsState>(
      (e) => state.copyWith(loadingMore: false, error: e),
      (page) => state.copyWith(
        loadingMore: false,
        posts: [...state.posts, ...page.posts],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
      ),
    );
  }

  /// Optimistic reaction toggle. Reverts on server error.
  Future<void> toggleReaction(String postId, ReactionType type) async {
    final currentIdx = state.posts.indexWhere((p) => p.id == postId);
    if (currentIdx == -1) return;
    final original = state.posts[currentIdx];
    final existing = original.currentUserReaction;
    int nextCount = original.reactionCount;
    ReactionType? nextReaction;
    if (existing == type) {
      nextCount = nextCount - 1;
      nextReaction = null;
    } else if (existing == null) {
      nextCount = nextCount + 1;
      nextReaction = type;
    } else {
      nextReaction = type;
    }
    _updatePost(
      currentIdx,
      original.copyWith(
        reactionCount: nextCount < 0 ? 0 : nextCount,
        currentUserReaction: nextReaction,
        clearReaction: nextReaction == null,
      ),
    );
    final repo = _ref.read(postsRepositoryProvider);
    final result = await repo.toggleReaction(postId: postId, type: type);
    result.fold(
      (_) => _updatePost(currentIdx, original),
      (res) => _updatePost(
        currentIdx,
        original.copyWith(
          reactionCount: res.reactionCount,
          currentUserReaction: res.currentUserReaction,
          clearReaction: res.currentUserReaction == null,
        ),
      ),
    );
  }

  /// Inserts a freshly created post at the top.
  void insertPost(Post post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  void _updatePost(int index, Post next) {
    final list = [...state.posts];
    if (index >= 0 && index < list.length) {
      list[index] = next;
      state = state.copyWith(posts: list);
    }
  }
}

/// Async mutation state for consultation form submission.
final consultationRequestProvider = AsyncNotifierProvider<
    ConsultationRequestNotifier, String?>(ConsultationRequestNotifier.new);

/// Handles consultation request submissions.
class ConsultationRequestNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  /// Submits a consultation request and returns created request id.
  Future<String?> submit({
    required String garmentType,
    required String description,
    double? budgetMin,
    double? budgetMax,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(communityRepositoryProvider);
    final result = await repo.requestConsultation(
      garmentType: garmentType,
      description: description,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
    );
    final next = result.fold<AsyncValue<String?>>(
      (e) => AsyncValue.error(
        CommunityProviderException(e),
        StackTrace.current,
      ),
      AsyncValue.data,
    );
    state = next;
    return next.valueOrNull;
  }
}

/// Current user's consultations (customer-side).
final myConsultationsProvider = FutureProvider<List<Consultation>>(
  (ref) async {
    final repo = ref.watch(communityRepositoryProvider);
    final result = await repo.listConsultations();
    return result.fold<List<Consultation>>(
      (e) => throw CommunityProviderException(e),
      (items) => items,
    );
  },
);

/// Single post loader for [PostDetailScreen].
final postDetailProvider =
    FutureProvider.family.autoDispose<Post, String>((ref, id) async {
  final repo = ref.watch(postsRepositoryProvider);
  final result = await repo.getPost(id);
  return result.fold<Post>(
    (e) => throw CommunityProviderException(e),
    (post) => post,
  );
});

/// Comments list for [PostDetailScreen]. Cached per post id.
final postCommentsProvider = AsyncNotifierProvider.family<
    PostCommentsNotifier, List<PostComment>, String>(
  PostCommentsNotifier.new,
);

/// Paginated-enough comments list with append-on-create.
class PostCommentsNotifier
    extends FamilyAsyncNotifier<List<PostComment>, String> {
  @override
  Future<List<PostComment>> build(String postId) async {
    final repo = ref.watch(postsRepositoryProvider);
    final result = await repo.getComments(postId);
    return result.fold<List<PostComment>>(
      (e) => throw CommunityProviderException(e),
      (items) => items,
    );
  }

  /// Adds a comment and appends locally on success.
  Future<PostComment> addComment(String body) async {
    final repo = ref.read(postsRepositoryProvider);
    final result = await repo.addComment(postId: arg, body: body);
    return result.fold<PostComment>(
      (e) => throw CommunityProviderException(e),
      (created) {
        final current = state.valueOrNull ?? const [];
        state = AsyncValue.data([...current, created]);
        return created;
      },
    );
  }
}

/// Showcase sort mode (persisted between tab switches).
final showcaseSortProvider =
    StateProvider<ShowcaseSort>((_) => ShowcaseSort.trending);

/// Paginated showcase state.
class ShowcaseFeedState {
  /// Creates a showcase state.
  const ShowcaseFeedState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
  });

  /// Rendered items.
  final List<ShowcaseItem> items;

  /// Whether the first page is loading.
  final bool loading;

  /// Whether a further page is loading.
  final bool loadingMore;

  /// Latest error.
  final Object? error;

  /// Next cursor (int offset).
  final int? nextCursor;

  /// Clone helper.
  ShowcaseFeedState copyWith({
    List<ShowcaseItem>? items,
    bool? loading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
    int? nextCursor,
    bool clearCursor = false,
  }) {
    return ShowcaseFeedState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : error ?? this.error,
      nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    );
  }
}

/// Showcase state notifier driven by [showcaseSortProvider].
final showcaseFeedProvider =
    StateNotifierProvider<ShowcaseFeedNotifier, ShowcaseFeedState>(
  ShowcaseFeedNotifier.new,
);

/// Showcase notifier.
class ShowcaseFeedNotifier extends StateNotifier<ShowcaseFeedState> {
  /// Creates the notifier.
  ShowcaseFeedNotifier(this._ref) : super(const ShowcaseFeedState()) {
    _ref.listen<ShowcaseSort>(showcaseSortProvider, (_, __) => refresh());
    loadFirstPage();
  }

  final Ref _ref;

  /// Loads the first page under the current sort.
  Future<void> loadFirstPage() async {
    state = state.copyWith(loading: true, clearError: true);
    final sort = _ref.read(showcaseSortProvider);
    final repo = _ref.read(showcaseRepositoryProvider);
    final result = await repo.list(sort: sort);
    state = result.fold<ShowcaseFeedState>(
      (e) => state.copyWith(loading: false, error: e),
      (page) => ShowcaseFeedState(
        items: page.items,
        loading: false,
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Reload under the currently-selected sort.
  Future<void> refresh() => loadFirstPage();

  /// Appends the next page.
  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || state.nextCursor == null) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    final repo = _ref.read(showcaseRepositoryProvider);
    final sort = _ref.read(showcaseSortProvider);
    final result = await repo.list(sort: sort, cursor: state.nextCursor);
    state = result.fold<ShowcaseFeedState>(
      (e) => state.copyWith(loadingMore: false, error: e),
      (page) => state.copyWith(
        items: [...state.items, ...page.items],
        loadingMore: false,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
      ),
    );
  }
}

/// Pro-designers list.
final proDesignersProvider =
    FutureProvider.autoDispose<List<DesignerProfile>>((ref) async {
  final repo = ref.watch(designersRepositoryProvider);
  final result = await repo.getProDesigners();
  return result.fold<List<DesignerProfile>>(
    (e) => throw CommunityProviderException(e),
    (items) => items,
  );
});

/// Single designer profile loader with follow toggle.
final designerProfileProvider = AsyncNotifierProvider.family<
    DesignerProfileNotifier, DesignerProfile, String>(
  DesignerProfileNotifier.new,
);

/// Designer profile notifier.
class DesignerProfileNotifier
    extends FamilyAsyncNotifier<DesignerProfile, String> {
  @override
  Future<DesignerProfile> build(String designerId) async {
    final repo = ref.watch(designersRepositoryProvider);
    final result = await repo.getDesigner(designerId);
    return result.fold<DesignerProfile>(
      (e) => throw CommunityProviderException(e),
      (item) => item,
    );
  }

  /// Toggle follow with optimistic flip.
  Future<void> toggleFollow() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = current.copyWith(
      isFollowing: !current.isFollowing,
      followerCount: current.isFollowing
          ? (current.followerCount - 1).clamp(0, 1 << 31)
          : current.followerCount + 1,
    );
    state = AsyncValue.data(next);
    final repo = ref.read(designersRepositoryProvider);
    final result = current.isFollowing
        ? await repo.unfollow(current.id)
        : await repo.follow(current.id);
    result.fold(
      (e) {
        state = AsyncValue.data(current);
      },
      (r) {
        state = AsyncValue.data(
          current.copyWith(
            isFollowing: r.followed,
            followerCount: r.followerCount,
          ),
        );
      },
    );
  }
}

/// A designer's public designs (for profile screen).
final designerPublicDesignsProvider = FutureProvider.family
    .autoDispose<List<ShowcaseItem>, DesignerProfile>((ref, profile) async {
  final repo = ref.watch(designersRepositoryProvider);
  final result = await repo.getDesignerDesigns(
    profile.id,
    fallbackDesignerName: profile.name,
    designerIsPro: profile.isProDesigner,
  );
  return result.fold<List<ShowcaseItem>>(
    (e) => throw CommunityProviderException(e),
    (items) => items,
  );
});

/// Earnings roll-up for the current user.
final designerEarningsProvider =
    FutureProvider.autoDispose<DesignerEarnings>((ref) async {
  final repo = ref.watch(designersRepositoryProvider);
  final result = await repo.getMyEarnings();
  return result.fold<DesignerEarnings>(
    (e) => throw CommunityProviderException(e),
    (item) => item,
  );
});

/// Commission list for the current user.
final myCommissionsProvider =
    FutureProvider.autoDispose.family<List<Commission>, String?>(
  (ref, status) async {
    final repo = ref.watch(designersRepositoryProvider);
    final result = await repo.getMyCommissions(status: status);
    return result.fold<List<Commission>>(
      (e) => throw CommunityProviderException(e),
      (items) => items,
    );
  },
);

/// Exception wrapper for community provider failures.
class CommunityProviderException implements Exception {
  /// Creates wrapper around [cause].
  const CommunityProviderException(this.cause);

  /// Underlying app exception.
  final AppException cause;
}

/// Human-friendly message for community-related async errors.
String communityErrorMessage(
  Object error, {
  String fallback = 'Something went wrong in community.',
}) {
  final appError = switch (error) {
    CommunityProviderException(cause: final cause) => cause,
    AppException() => error,
    _ => null,
  };
  if (appError == null) return fallback;
  return mapAppExceptionMessage(
    appError,
    fallback: fallback,
    networkMessage:
        'Network issue while contacting community service. Please retry.',
    authMessage: 'Your session has expired. Please sign in again.',
    statusMessages: const {
      403: 'You do not have permission for this community action.',
    },
  );
}
