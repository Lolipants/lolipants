import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/providers/news_providers.dart';
import 'package:lolipants/shared/widgets/arabesque_background.dart';

/// Full-screen fashion news article detail.
class NewsArticleDetailScreen extends ConsumerWidget {
  /// Creates the detail screen for [articleId].
  const NewsArticleDetailScreen({required this.articleId, super.key});

  /// Article id from the route.
  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsArticleProvider(articleId));

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.sand,
        title: Text(
          localizedFromContext(
            context,
            CommunityStrings.newsArticleTitle,
            CommunityStrings.newsArticleTitleAr,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ArabesqueBackground(opacity: 0.1),
          async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  localizedFromContext(
                    context,
                    CommunityStrings.newsLoadError,
                    CommunityStrings.newsLoadErrorAr,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
            data: (article) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (article.coverImageUrl != null &&
                      article.coverImageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: CachedNetworkImage(
                          imageUrl: article.coverImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    article.title,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.sand,
                    ),
                  ),
                  if (article.publishedAt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      DateFormat.yMMMd().format(article.publishedAt!),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.fog,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    article.body,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.sand,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
