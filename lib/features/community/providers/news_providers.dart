import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/community/data/news_repository.dart';
import 'package:lolipants/features/community/models/news_article.dart';
import 'package:lolipants/features/community/providers/community_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/settings/providers/settings_provider.dart';

/// Repository for fashion news articles.
final newsRepositoryProvider = Provider<NewsRepository>(
  (ref) => NewsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Published fashion news for the News tab hero.
final fashionNewsProvider = FutureProvider<FashionNewsPage>((ref) async {
  ref.watch(settingsLocaleProvider);
  final lang = ref.watch(settingsLocaleProvider).languageCode;
  final repo = ref.watch(newsRepositoryProvider);
  final result = await repo.getNews(lang: lang);
  return result.fold(
    (e) => throw CommunityProviderException(e),
    (page) => page,
  );
});

/// Single fashion news article for the detail screen.
final newsArticleProvider =
    FutureProvider.family.autoDispose<NewsArticle, String>((ref, id) async {
  ref.watch(settingsLocaleProvider);
  final lang = ref.watch(settingsLocaleProvider).languageCode;
  final repo = ref.watch(newsRepositoryProvider);
  final result = await repo.getArticle(id, lang: lang);
  return result.fold(
    (e) => throw CommunityProviderException(e),
    (article) => article,
  );
});
