import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/editor/models/configurator_catalog.dart';

class ConfiguratorRepository {
  ConfiguratorRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppException, ConfiguratorCatalog>> fetchCatalog() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.configuratorTemplates,
      );
      final items = response.data ?? const <dynamic>[];
      return right(ConfiguratorCatalog.fromApi(items));
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
