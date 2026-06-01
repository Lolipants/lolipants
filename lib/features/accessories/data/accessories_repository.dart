import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/accessories/data/bundled_accessories.dart';
import 'package:lolipants/features/accessories/models/accessory.dart';

/// Public accessories catalogue API.
class AccessoriesRepository {
  AccessoriesRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppException, List<Accessory>>> listAccessories({
    AccessoryCategoryFilter filter = AccessoryCategoryFilter.all,
  }) async {
    try {
      final category = accessoryCategoryFilterApiValue(filter);
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.accessories,
        queryParameters:
            category.isEmpty ? null : <String, String>{'category': category},
      );
      final items = response.data ?? const <dynamic>[];
      final accessories = items
          .whereType<Map<String, dynamic>>()
          .map(Accessory.fromJson)
          .where((a) => a.id.isNotEmpty)
          .toList(growable: false);
      if (accessories.isEmpty) {
        return right(filterBundledAccessories(filter));
      }
      return right(accessories);
    } on DioException catch (_) {
      return right(filterBundledAccessories(filter));
    } on Exception {
      return right(filterBundledAccessories(filter));
    }
  }
}
