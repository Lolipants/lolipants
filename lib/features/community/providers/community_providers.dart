import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/community/data/community_repository.dart';
import 'package:lolipants/features/community/models/post.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// API-backed community repository.
final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => CommunityRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Basic feed list provider.
final feedPostsProvider =
    FutureProvider.family<List<Post>, String?>((ref, tag) async {
  final repo = ref.watch(communityRepositoryProvider);
  final result = await repo.getPosts(tag: tag);
  return result.fold<List<Post>>(
    (e) => throw CommunityProviderException(e),
    (posts) => posts,
  );
});

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
