import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/features/community/models/comment.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/community/widgets/post_card.dart';
import 'package:lolipants/features/community/widgets/user_avatar.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';
import 'package:lolipants/shared/widgets/error_banner.dart';

/// Single post detail with comments + reply composer.
class PostDetailScreen extends ConsumerStatefulWidget {
  /// Creates the post detail screen.
  const PostDetailScreen({required this.postId, this.initialPost, super.key});

  /// Post id.
  final String postId;

  /// Optional initial post (passed via navigation extra).
  final Post? initialPost;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Comment cannot be empty.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(postCommentsProvider(widget.postId).notifier)
          .addComment(text);
      if (!mounted) return;
      _commentController.clear();
      ref.invalidate(postDetailProvider(widget.postId));
    } on Object catch (e) {
      if (!mounted) return;
      setState(
        () => _error = communityErrorMessage(
          e,
          fallback: 'Could not post comment.',
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));

    final displayPost = postAsync.valueOrNull ?? widget.initialPost;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Post', style: AppTextStyles.titleLarge),
      ),
      body: Stack(
        children: [
          const ArabesqueBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      if (displayPost != null)
                        PostCard(
                          post: displayPost,
                          onToggleReaction: (type) => ref
                              .read(feedPostsProvider(null).notifier)
                              .toggleReaction(displayPost.id, type),
                          onOpenDetail: () {},
                          onTapAuthor: () => context.push(
                            '/community/designer/${displayPost.authorId}',
                          ),
                        ),
                      if (displayPost == null)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      const _CommentsHeader(),
                      commentsAsync.when(
                        data: (comments) {
                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Text(
                                  'No comments yet. Start the conversation.',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              for (final comment in comments)
                                _CommentTile(comment: comment),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            communityErrorMessage(
                              error,
                              fallback: 'Could not load comments.',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: ErrorBanner(
                      message: _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),
                  ),
                _Composer(
                  controller: _commentController,
                  sending: _sending,
                  onSubmit: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsHeader extends StatelessWidget {
  const _CommentsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Text('Comments', style: AppTextStyles.titleSmall),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd().add_jm();
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            name: comment.authorName,
            avatarUrl: comment.authorAvatarUrl,
            isProDesigner: comment.isVerifiedDesigner,
            radius: 14,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName, style: AppTextStyles.titleSmall),
                    const Spacer(),
                    Text(
                      fmt.format(comment.createdAt.toLocal()),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.body, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.stone,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.smoke,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyLarge,
                cursorColor: AppColors.gold,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Write a comment',
                  hintStyle: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSubmit,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}
