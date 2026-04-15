import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/community/models/post.dart';

/// Repository for feed and consultation APIs.
class CommunityRepository {
  /// Creates repository instance.
  CommunityRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Fetches feed posts.
  Future<Either<AppException, List<Post>>> getPosts({
    String? tag,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.posts,
        queryParameters: {
          if (tag != null && tag.isNotEmpty) 'tag': tag,
          'page': page,
        },
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final posts = items
          .whereType<Map<String, dynamic>>()
          .map(Post.fromApi)
          .toList(growable: false);
      return right(posts);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Sends consultation request.
  Future<Either<AppException, String>> requestConsultation({
    required String garmentType,
    required String description,
    double? budgetMin,
    double? budgetMax,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.community}/consultations',
        data: {
          'garmentType': garmentType,
          'description': description,
          'budgetMin': budgetMin,
          'budgetMax': budgetMax,
        },
        options: await _authOptions(),
      );
      final id = response.data?['id']?.toString();
      if (id == null || id.isEmpty) {
        return left(const ServerException(500, 'Missing consultation id'));
      }
      return right(id);
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
    if (body is Map && body['error'] != null) {
      message = body['error'].toString();
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
