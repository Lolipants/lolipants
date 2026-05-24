import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/editor/models/design_catalog_item.dart';

class DesignCatalogRepository {
  DesignCatalogRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppException, List<DesignCatalogItem>>> fetchActiveItems() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.catalogDesigns);
      final sections = response.data?['sections'];
      if (sections is! List) return right(const []);

      final items = <DesignCatalogItem>[];
      for (final section in sections) {
        if (section is! Map) continue;
        final sectionTitle = section['sectionTitle']?.toString() ??
            section['section_title']?.toString() ??
            'Catalog';
        final rawItems = section['items'];
        if (rawItems is! List) continue;
        for (final raw in rawItems) {
          if (raw is Map<String, dynamic>) {
            items.add(DesignCatalogItem.fromJson({
              ...raw,
              'sectionTitle': sectionTitle,
            }));
          } else if (raw is Map) {
            items.add(DesignCatalogItem.fromJson({
              ...Map<String, dynamic>.from(raw),
              'sectionTitle': sectionTitle,
            }));
          }
        }
      }
      return right(items);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map) {
      final err = body['error'];
      if (err is Map && err['message'] != null) {
        message = err['message'].toString();
      }
    }
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
