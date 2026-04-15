import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/browse/models/mannequin_option.dart';

/// Loads mannequin options and triggers Meshy generation through backend.
class MannequinsRepository {
  MannequinsRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  Future<Either<AppException, List<MannequinOption>>> getMannequins() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.mannequins,
        options: await _authOptions(),
      );
      final list = response.data ?? const <dynamic>[];
      final options = list
          .whereType<Map<String, dynamic>>()
          .map(MannequinOption.fromApi)
          .where((m) => m.id.isNotEmpty)
          .toList(growable: false);
      return right(options);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Calls backend endpoint that proxies Meshy API generation.
  Future<Either<AppException, MannequinOption>> generateFromPhoto({
    required String photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath, filename: 'photo.jpg'),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiMannequin,
        data: formData,
        options: await _authOptions(contentType: 'multipart/form-data'),
      );
      final body = response.data ?? const <String, dynamic>{};
      return right(MannequinOption.fromApi(body));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Options> _authOptions({String? contentType}) async {
    final headers = <String, dynamic>{};
    final token = await _storage.readSessionToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (contentType != null) {
      headers['Content-Type'] = contentType;
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
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
