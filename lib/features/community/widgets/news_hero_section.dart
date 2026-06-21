import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolipants/core/constants/app_colors.dart';
import 'package:lolipants/core/constants/app_spacing.dart';
import 'package:lolipants/core/constants/app_text_styles.dart';
import 'package:lolipants/core/constants/community_strings.dart';
import 'package:lolipants/core/l10n/app_localization.dart';
import 'package:lolipants/features/community/models/news_article.dart';
import 'package:lolipants/features/community/providers/news_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Editorial fashion news hero and recent article strip for the News tab.
class NewsHeroSection extends ConsumerWidget {
  const NewsHeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fashionNewsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (page) {
        if (page.featured == null && page.articles.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              localizedFromContext(
                context,
                CommunityStrings.newsEmptyHero,
                CommunityStrings.newsEmptyHeroAr,
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.fog),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(),
              if (page.featured != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _FeaturedCard(
                  article: page.featured!,
                  onTap: () => context.push('/community/news/${page.featured!.id}'),
                ),
              ],
              if (page.articles.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: page.articles.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final article = page.articles[index];
                      return _RecentCard(
                        article: article,
                        onTap: () =>
                            context.push('/community/news/${article.id}'),
                      );
                    },
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

class _SectionTitle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsLocaleProvider);
    final isAr = locale.languageCode == 'ar';
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            localizedFromContext(
              context,
              CommunityStrings.newsSectionTitle,
              CommunityStrings.newsSectionTitleAr,
            ),
            style: (isAr
                    ? AppTextStyles.titleMedium.copyWith(
                        fontFamily: AppTextStyles.arabicBody.fontFamily,
                      )
                    : AppTextStyles.titleMedium)
                .copyWith(
              color: AppColors.sand,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ember,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (article.coverImageUrl != null && article.coverImageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: AppColors.ink,
                    child: Icon(Icons.image_outlined, color: AppColors.fog),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.sand,
                      height: 1.2,
                    ),
                  ),
                  if (article.summary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      article.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.fog,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    localizedFromContext(
                      context,
                      CommunityStrings.newsReadMore,
                      CommunityStrings.newsReadMoreAr,
                    ),
                    style: AppTextStyles.labelGold.copyWith(fontSize: 12),
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

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              if (article.coverImageUrl != null &&
                  article.coverImageUrl!.isNotEmpty)
                SizedBox(
                  width: 72,
                  height: 168,
                  child: CachedNetworkImage(
                    imageUrl: article.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.sand,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        localizedFromContext(
                          context,
                          CommunityStrings.newsReadMore,
                          CommunityStrings.newsReadMoreAr,
                        ),
                        style: AppTextStyles.labelGold.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
