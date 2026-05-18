import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/wedding/data/bundled_wedding_dresses.dart';
import 'package:lolipants/features/wedding/models/wedding_dress.dart';

/// Public wedding dress catalogue API.
class WeddingRepository {
  WeddingRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  Future<Either<AppException, List<WeddingDress>>> listDresses({
    WeddingCategoryFilter filter = WeddingCategoryFilter.all,
  }) async {
    try {
      final category = weddingCategoryFilterApiValue(filter);
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.weddingDresses,
        queryParameters:
            category.isEmpty ? null : <String, String>{'category': category},
      );
      final items = response.data ?? const <dynamic>[];
      final dresses = items
          .whereType<Map<String, dynamic>>()
          .map(WeddingDress.fromJson)
          .where((d) => d.id.isNotEmpty)
          .toList(growable: false);
      if (dresses.isEmpty) {
        return right(filterBundledWeddingDresses(filter));
      }
      return right(dresses);
    } on DioException catch (_) {
      return right(filterBundledWeddingDresses(filter));
    } on Exception {
      return right(filterBundledWeddingDresses(filter));
    }
  }

  Future<Options> _authOptions() async {
    final token = await _storage.readSessionToken();
    return Options(
      headers: token == null ? null : <String, String>{'Authorization': 'Bearer $token'},
    );
  }
}
