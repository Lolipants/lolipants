import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/community/widgets/user_avatar.dart';

/// Card showing a community post with reaction toggle and tap-to-open.
class PostCard extends ConsumerWidget {
  /// Creates a post card.
  const PostCard({
    required this.post,
    required this.onToggleReaction,
    required this.onOpenDetail,
    this.onTapAuthor,
    super.key,
  });

  /// Post to render.
  final Post post;

  /// Called when the reaction button is tapped.
  final ValueChanged<ReactionType> onToggleReaction;

  /// Called when the user taps the card body / comment button.
  final VoidCallback onOpenDetail;

  /// Called when the author row is tapped.
  final VoidCallback? onTapAuthor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.stone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorRow(post: post, onTap: onTapAuthor),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: onOpenDetail,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                post.body,
                style: AppTextStyles.bodyLarge,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _ImagesStrip(urls: post.imageUrls, onTap: onOpenDetail),
          ],
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in post.tags) _TagPill(tag: tag),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _ActionsRow(
            post: post,
            onToggleReaction: onToggleReaction,
            onOpenDetail: onOpenDetail,
          ),
        ],
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post, this.onTap});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.MMMd().add_jm();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            UserAvatar(
              name: post.authorName,
              avatarUrl: post.authorAvatarUrl,
              isProDesigner: post.isVerifiedDesigner,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName,
                          style: AppTextStyles.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.isVerifiedDesigner) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.gold,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    formatter.format(post.postedAt.toLocal()),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Portrait-friendly frame for garment / look photos in the feed.
const double _postImageAspectRatio = 3 / 4;

/// Neutral backdrop when the image does not fill the frame.
const Color _postImageBackdrop = Color(0xFFF5F5F5);

class _ImagesStrip extends StatelessWidget {
  const _ImagesStrip({required this.urls, required this.onTap});

  final List<String> urls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return AspectRatio(
        aspectRatio: _postImageAspectRatio,
        child: _PostImageTile(url: urls.first, onTap: onTap),
      );
    }

    final max = urls.length > 3 ? 3 : urls.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final overflowWidth = urls.length > 3 ? 64.0 + gap : 0.0;
        final gaps = gap * (max - 1);
        final cellWidth = (constraints.maxWidth - gaps - overflowWidth) / max;
        final cellHeight = cellWidth / _postImageAspectRatio;

        return SizedBox(
          height: cellHeight,
          child: Row(
            children: [
              for (var i = 0; i < max; i++) ...[
                SizedBox(
                  width: cellWidth,
                  height: cellHeight,
                  child: _PostImageTile(url: urls[i], onTap: onTap),
                ),
                if (i < max - 1) const SizedBox(width: gap),
              ],
              if (urls.length > 3) ...[
                const SizedBox(width: gap),
                Container(
                  width: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.smoke,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    '+${urls.length - 3}',
                    style: AppTextStyles.titleSmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PostImageTile extends StatelessWidget {
  const _PostImageTile({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ColoredBox(
          color: _postImageBackdrop,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => Container(
              color: AppColors.smoke,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.fog,
              ),
            ),
            placeholder: (_, __) => Container(
              color: AppColors.smoke,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text('#$tag', style: AppTextStyles.labelGold),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.post,
    required this.onToggleReaction,
    required this.onOpenDetail,
  });

  final Post post;
  final ValueChanged<ReactionType> onToggleReaction;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReactionButton(
          active: post.currentUserReaction == ReactionType.love,
          icon: post.currentUserReaction == ReactionType.love
              ? Icons.favorite
              : Icons.favorite_border,
          label: '${post.reactionCount}',
          onTap: () => onToggleReaction(ReactionType.love),
          semanticsLabel: post.currentUserReaction == ReactionType.love
              ? localizedFromContext(
                  context,
                  CommunityStrings.unlikePost,
                  CommunityStrings.unlikePostAr,
                )
              : localizedFromContext(
                  context,
                  CommunityStrings.likePost,
                  CommunityStrings.likePostAr,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        _ReactionButton(
          active: post.currentUserReaction == ReactionType.fire,
          icon: Icons.local_fire_department_outlined,
          label: localizedFromContext(
            context,
            CommunityStrings.fire,
            CommunityStrings.fireAr,
          ),
          onTap: () => onToggleReaction(ReactionType.fire),
          semanticsLabel: localizedFromContext(
            context,
            CommunityStrings.fireReaction,
            CommunityStrings.fireReactionAr,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _ReactionButton(
          active: post.currentUserReaction == ReactionType.clap,
          icon: Icons.celebration_outlined,
          label: localizedFromContext(
            context,
            CommunityStrings.clap,
            CommunityStrings.clapAr,
          ),
          onTap: () => onToggleReaction(ReactionType.clap),
          semanticsLabel: localizedFromContext(
            context,
            CommunityStrings.clapReaction,
            CommunityStrings.clapReactionAr,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onOpenDetail,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.mode_comment_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.sand,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.semanticsLabel,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.dust;
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
