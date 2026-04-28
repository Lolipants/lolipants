import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';

/// Sort modes available on the showcase grid.
enum ShowcaseSort { trending, newest, mostOrdered }

/// Converts a [ShowcaseSort] to the backend query string.
String showcaseSortToQuery(ShowcaseSort sort) {
  switch (sort) {
    case ShowcaseSort.trending:
      return 'trending';
    case ShowcaseSort.newest:
      return 'newest';
    case ShowcaseSort.mostOrdered:
      return 'most_ordered';
  }
}

/// One page of showcase items.
class ShowcasePage {
  /// Creates a showcase page.
  const ShowcasePage({required this.items, required this.nextCursor});

  /// Items in this page.
  final List<ShowcaseItem> items;

  /// Cursor for the next page, or null if end of list.
  final int? nextCursor;
}

/// Repository for the /showcase endpoint.
class ShowcaseRepository {
  /// Creates the repository.
  ShowcaseRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Loads one page of the showcase grid.
  Future<Either<AppException, ShowcasePage>> list({
    ShowcaseSort sort = ShowcaseSort.trending,
    String? garment,
    int? cursor,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.showcase,
        queryParameters: {
          'sort': showcaseSortToQuery(sort),
          if (garment != null && garment.isNotEmpty) 'garment': garment,
          if (cursor != null) 'cursor': cursor,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing showcase payload'));
      }
      final raw = data['items'];
      final list = raw is List ? raw : const <dynamic>[];
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(ShowcaseItem.fromApi)
          .toList(growable: false);
      final nextCursor = data['nextCursor'];
      return right(
        ShowcasePage(
          items: items,
          nextCursor: nextCursor is num ? nextCursor.toInt() : null,
        ),
      );
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
      final nested = body['error'];
      if (nested is Map && nested['message'] != null) {
        message = nested['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkException(message);
    }
    if (status == 401 || status == 403) return AuthException(message);
    if (status >= 500) return ServerException(status, message);
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
