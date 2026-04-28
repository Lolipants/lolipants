import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/community/models/commission.dart';
import 'package:lolipants/features/community/models/designer_profile.dart';
import 'package:lolipants/features/community/models/showcase_item.dart';

/// Follow toggle result.
class FollowResult {
  /// Creates a follow result.
  const FollowResult({required this.followed, required this.followerCount});

  /// Whether the viewer now follows the designer.
  final bool followed;

  /// Updated follower count.
  final int followerCount;
}

/// Repository for designer/follow/commission APIs.
class DesignersRepository {
  /// Creates the repository.
  DesignersRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Lists Pro designers sorted by followers.
  Future<Either<AppException, List<DesignerProfile>>> getProDesigners() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.designers}/pro',
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items
            .whereType<Map<String, dynamic>>()
            .map(DesignerProfile.fromApi)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Loads a single designer profile.
  Future<Either<AppException, DesignerProfile>> getDesigner(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.designers}/$id',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing designer payload'));
      }
      return right(DesignerProfile.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Lists a designer's public designs as showcase items.
  Future<Either<AppException, List<ShowcaseItem>>> getDesignerDesigns(
    String id, {
    required String fallbackDesignerName,
    bool designerIsPro = false,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.designers}/$id/designs',
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items.whereType<Map<String, dynamic>>().map((json) {
          return ShowcaseItem.fromApi({
            ...json,
            'designId': json['id'],
            'previewImageUrl': json['print_image_url'],
            'orderCount': json['order_count'] ?? 0,
            'trendingScore': json['order_count'] ?? 0,
            'designer': {
              'id': id,
              'name': fallbackDesignerName,
              'isProDesigner': designerIsPro,
            },
          });
        }).toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Current user's earnings roll-up.
  Future<Either<AppException, DesignerEarnings>> getMyEarnings() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.designers}/me/earnings',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing earnings payload'));
      }
      return right(DesignerEarnings.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Current user's commission rows.
  Future<Either<AppException, List<Commission>>> getMyCommissions({
    String? status,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.designers}/me/commissions',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items
            .whereType<Map<String, dynamic>>()
            .map(Commission.fromApi)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Follows a designer.
  Future<Either<AppException, FollowResult>> follow(String designerId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.community}/follow/$designerId',
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return right(
        FollowResult(
          followed: data['followed'] == true,
          followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Unfollows a designer.
  Future<Either<AppException, FollowResult>> unfollow(String designerId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '${ApiEndpoints.community}/follow/$designerId',
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return right(
        FollowResult(
          followed: data['followed'] == true,
          followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
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
