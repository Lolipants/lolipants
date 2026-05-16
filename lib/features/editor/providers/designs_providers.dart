import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/editor/data/designs_repository.dart';
import 'package:lolipants/features/editor/data/render_preview_repository.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// API-backed designs repository.
final designsRepositoryProvider = Provider<DesignsRepository>(
  (ref) => DesignsRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// API-backed preview render repository.
final renderPreviewRepositoryProvider = Provider<RenderPreviewRepository>(
  (ref) => RenderPreviewRepository(dio: ref.watch(apiDioProvider)),
);

/// User's saved designs list state.
final myDesignsProvider =
    AsyncNotifierProvider<MyDesignsNotifier, List<GarmentDesign>>(
  MyDesignsNotifier.new,
);

/// Creates and refreshes the designs list.
class MyDesignsNotifier extends AsyncNotifier<List<GarmentDesign>> {
  @override
  Future<List<GarmentDesign>> build() async {
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.getMyDesigns();
    return result.fold<List<GarmentDesign>>(
      (e) => throw DesignsProviderException(e),
      (designs) => designs,
    );
  }

  /// Reloads designs from backend.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(designsRepositoryProvider);
      final result = await repo.getMyDesigns();
      return result.fold<List<GarmentDesign>>(
        (e) => throw DesignsProviderException(e),
        (designs) => designs,
      );
    });
  }

  /// Deletes a design on the server and removes it from the current list.
  Future<void> deleteDesign(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      throw const DesignsProviderException(
        ServerException(400, 'Design id is missing'),
      );
    }
    final repo = ref.read(designsRepositoryProvider);
    final result = await repo.deleteDesign(trimmed);
    result.fold(
      (e) => throw DesignsProviderException(e),
      (_) {
        final current = state.valueOrNull;
        if (current != null) {
          state = AsyncData(
            current.where((d) => d.id != trimmed).toList(growable: false),
          );
        } else {
          ref.invalidateSelf();
        }
      },
    );
  }
}

/// Exception wrapper for design provider failures.
class DesignsProviderException implements Exception {
  /// Creates wrapper around [cause].
  const DesignsProviderException(this.cause);

  /// Underlying app-layer exception.
  final AppException cause;
}

/// Human-friendly message for design-related async errors.
String designErrorMessage(
  Object error, {
  String fallback = 'Something went wrong with designs.',
}) {
  final appError = switch (error) {
    DesignsProviderException(cause: final cause) => cause,
    AppException() => error,
    _ => null,
  };
  if (appError == null) return fallback;
  return mapAppExceptionMessage(
    appError,
    fallback: fallback,
    networkMessage:
        'Network issue while contacting designs service. Please retry.',
    authMessage: 'Your session has expired. Please sign in again.',
    statusMessages: const {
      403: 'You do not have permission for this design action.',
      404: 'The requested design could not be found.',
      409:
          'This design cannot be deleted because it is linked to an order.',
    },
  );
}
