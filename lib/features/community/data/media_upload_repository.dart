import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';

/// Reusable wrapper around `POST /upload` for community image uploads.
class MediaUploadRepository {
  /// Creates the repository.
  MediaUploadRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Uploads an image from a local file path. Returns the hosted URL.
  Future<Either<AppException, String>> uploadFile({
    required String filePath,
    String filename = 'upload.jpg',
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: filename),
      });
      return await _send(form);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Uploads raw image bytes (used by the editor share flow that renders a
  /// preview widget to a PNG in-memory).
  Future<Either<AppException, String>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    String contentType = 'image/png',
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      return await _send(form);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, String>> _send(FormData form) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.upload,
      data: form,
      options: await _authOptions('multipart/form-data'),
    );
    final data = response.data ?? const <String, dynamic>{};
    final url = data['url']?.toString() ??
        data['fileUrl']?.toString() ??
        data['path']?.toString() ??
        '';
    if (url.isEmpty) {
      return left(const ServerException(500, 'Upload response missing URL'));
    }
    return right(url);
  }

  Future<Options> _authOptions(String contentType) async {
    final headers = <String, dynamic>{'Content-Type': contentType};
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
