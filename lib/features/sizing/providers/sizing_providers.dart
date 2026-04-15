import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/errors/app_exception_message_mapper.dart';
import 'package:lolipants/features/auth/providers/auth_providers.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';
import 'package:lolipants/features/sizing/data/sizing_repository.dart';
import 'package:lolipants/features/sizing/models/body_measurements.dart';

/// API-backed sizing repository.
final sizingRepositoryProvider = Provider<SizingRepository>(
  (ref) => SizingRepository(
    dio: ref.watch(apiDioProvider),
    storage: ref.watch(authLocalStorageProvider),
  ),
);

/// Latest saved measurements state.
final myMeasurementsProvider = AsyncNotifierProvider<
    MyMeasurementsNotifier, BodyMeasurements?>(MyMeasurementsNotifier.new);

/// Reads and refreshes measurements state.
class MyMeasurementsNotifier extends AsyncNotifier<BodyMeasurements?> {
  @override
  Future<BodyMeasurements?> build() async {
    final repo = ref.read(sizingRepositoryProvider);
    final result = await repo.getMyMeasurements();
    return result.fold<BodyMeasurements?>(
      (e) => throw SizingProviderException(e),
      (m) => m,
    );
  }

  /// Persists measurements and updates state.
  Future<void> save(BodyMeasurements measurements) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sizingRepositoryProvider);
      final result = await repo.saveMeasurements(measurements);
      return result.fold<BodyMeasurements?>(
        (e) => throw SizingProviderException(e),
        (m) => m,
      );
    });
  }

  /// Reloads from backend.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sizingRepositoryProvider);
      final result = await repo.getMyMeasurements();
      return result.fold<BodyMeasurements?>(
        (e) => throw SizingProviderException(e),
        (m) => m,
      );
    });
  }
}

/// Exception wrapper for sizing providers.
class SizingProviderException implements Exception {
  /// Creates wrapper around [cause].
  const SizingProviderException(this.cause);

  /// Underlying app exception.
  final AppException cause;
}

/// Human-friendly message for measurement-related async errors.
String sizingErrorMessage(
  Object error, {
  String fallback = 'Something went wrong with measurements.',
}) {
  final appError = switch (error) {
    SizingProviderException(cause: final cause) => cause,
    AppException() => error,
    _ => null,
  };
  if (appError == null) return fallback;
  return mapAppExceptionMessage(
    appError,
    fallback: fallback,
    networkMessage: 'Network issue while saving measurements. Please retry.',
    authMessage: 'Your session has expired. Please sign in again.',
  );
}
