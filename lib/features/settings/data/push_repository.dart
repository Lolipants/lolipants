import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/features/orders/providers/orders_providers.dart';

/// Thin client for push-token registration.
class PushRepository {
  /// Creates a repository.
  PushRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Stores the OneSignal subscriber id server-side so the backend can
  /// target this user with transactional pushes.
  Future<Either<AppException, void>> registerPlayerId(
      String oneSignalId,) async {
    try {
      await _dio.post<void>(
        '/users/push-token',
        data: {
          'oneSignalId': oneSignalId,
        },
      );
      return right(null);
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'push-token failed'));
    } on Object catch (e) {
      return left(NetworkException(e.toString()));
    }
  }

  /// Clears the stored OneSignal id for the current user (opt-out / settings).
  Future<Either<AppException, void>> clearPushToken() async {
    try {
      await _dio.delete<void>('/users/push-token');
      return right(null);
    } on DioException catch (e) {
      return left(NetworkException(e.message ?? 'push-token delete failed'));
    } on Object catch (e) {
      return left(NetworkException(e.toString()));
    }
  }
}

/// Shared [PushRepository] hooked to the app Dio.
final pushRepositoryProvider = Provider<PushRepository>(
  (ref) => PushRepository(dio: ref.watch(apiDioProvider)),
);
