import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/tailor/models/tailor_wedding_pricing.dart';

class TailorWeddingPricingRepository {
  TailorWeddingPricingRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  Future<Either<AppException, TailorWeddingPricingCatalog>> getCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.tailorWeddingPricing,
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing wedding pricing'));
      }
      return right(TailorWeddingPricingCatalog.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, TailorWeddingPricingCatalog>> updatePrices(
    List<Map<String, dynamic>> prices,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.tailorWeddingPricing,
        data: {'prices': prices},
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing wedding pricing'));
      }
      return right(TailorWeddingPricingCatalog.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Options> _authOptions() async {
    final token = await _storage.readSessionToken();
    return Options(
      headers: token == null ? null : <String, String>{'Authorization': 'Bearer $token'},
    );
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final message = e.message ?? 'network';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(message);
    }
    if (status >= 400) return ServerException(status, message);
    return const UnknownException();
  }
}
