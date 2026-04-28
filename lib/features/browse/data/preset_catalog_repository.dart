import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/browse/data/region_presets.dart';

class PresetCatalogRepository {
  PresetCatalogRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppException, List<RegionStylePreset>>> getPresets() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.presets);
      final items = response.data ?? const <dynamic>[];
      final parsed = items
          .whereType<Map<String, dynamic>>()
          .map(RegionStylePreset.fromApi)
          .where((preset) => preset.id.isNotEmpty)
          .toList(growable: false);
      return right(parsed);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['error']?.toString() ?? e.message ?? 'network')
          : (e.message ?? 'network');
      if (status >= 400) {
        return left(ServerException(status, message));
      }
      return left(NetworkException(message));
    } on Exception {
      return left(const UnknownException());
    }
  }
}
