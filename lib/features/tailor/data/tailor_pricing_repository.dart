import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/tailor/models/tailor_pricing_catalog.dart';

/// API client for tailor workshop + price plan management.
class TailorPricingRepository {
  TailorPricingRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  Future<Either<AppException, TailorPricingCatalog>> getCatalog() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.tailorPricing,
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing pricing payload'));
      }
      return right(TailorPricingCatalog.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, TailorWorkshopProfile>> updateProfile({
    String? shopName,
    String? address,
    String? city,
    double? lat,
    double? lng,
    double? serviceRadiusKm,
    bool? isAcceptingOrders,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiEndpoints.tailorPricing}/profile',
        data: {
          if (shopName != null) 'shopName': shopName,
          if (address != null) 'address': address,
          if (city != null) 'city': city,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          if (serviceRadiusKm != null) 'serviceRadiusKm': serviceRadiusKm,
          if (isAcceptingOrders != null)
            'isAcceptingOrders': isAcceptingOrders,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing profile payload'));
      }
      return right(TailorWorkshopProfile.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, List<TailorGarmentPrice>>> saveGarmentPrices(
    List<TailorGarmentPrice> prices,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiEndpoints.tailorPricing}/garment-prices',
        data: {'prices': prices.map((p) => p.toApi()).toList()},
        options: await _authOptions(),
      );
      final rows = response.data?['garmentPrices'] as List<dynamic>? ?? [];
      return right(
        rows
            .whereType<Map<String, dynamic>>()
            .map(TailorGarmentPrice.fromApi)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, List<TailorDeliveryFee>>> saveDeliveryFees(
    List<TailorDeliveryFee> fees,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '${ApiEndpoints.tailorPricing}/delivery-fees',
        data: {'fees': fees.map((f) => f.toApi()).toList()},
        options: await _authOptions(),
      );
      final rows = response.data?['deliveryFees'] as List<dynamic>? ?? [];
      return right(
        rows
            .whereType<Map<String, dynamic>>()
            .map(TailorDeliveryFee.fromApi)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, void>> resetDefaults() async {
    try {
      await _dio.post<void>(
        '${ApiEndpoints.tailorPricing}/reset-defaults',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Options> _authOptions() async {
    final headers = <String, dynamic>{};
    final token = await _storage.readSessionToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return Options(headers: headers);
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map) {
      final nestedError = body['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        message = nestedError['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }
    }
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
