import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fpdart/fpdart.dart' show Either, Unit, left, right, unit;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/editor/data/bundled_fabric_catalog.dart';
import 'package:lolipants/features/editor/models/fabric_option.dart';
import 'package:lolipants/features/editor/models/garment_design.dart';

/// Repository for listing and creating user designs.
class DesignsRepository {
  /// Creates repository instance.
  DesignsRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Returns current user's saved designs.
  Future<Either<AppException, List<GarmentDesign>>> getMyDesigns() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.designs,
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final designs = items
          .whereType<Map<String, dynamic>>()
          .map(GarmentDesign.fromApi)
          .toList(growable: false);
      return right(designs);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Returns available fabric metadata for a garment type.
  Future<Either<AppException, List<FabricOption>>> getFabricsForGarmentType(
    String garmentType,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.fabrics,
        queryParameters: {'garmentType': garmentType},
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final options = <FabricOption>[];
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final fabric = FabricOption.fromApi(item);
          if (fabric.id.isNotEmpty) options.add(fabric);
        } else if (item is String && item.trim().isNotEmpty) {
          options.add(
            FabricOption(
              id: item.trim(),
              name: item.trim(),
              nameAr: item.trim(),
              quality: 'standard',
              isAvailable: true,
            ),
          );
        }
      }
      if (options.isEmpty) {
        return right(bundledFabricOptionsForGarment(garmentType));
      }
      return right(enrichFabricSwatches(options));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Persists a design draft.
  Future<Either<AppException, GarmentDesign>> createDesign({
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.designs,
        data: payload,
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing design payload'));
      }
      return right(GarmentDesign.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Updates an existing saved design.
  Future<Either<AppException, GarmentDesign>> updateDesign({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.designs}/$id',
        data: payload,
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing design payload'));
      }
      return right(GarmentDesign.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Publishes a design to the public showcase (requires preview).
  Future<Either<AppException, ({GarmentDesign design, int commissionPct})>>
      publishDesign(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.designs}/$id/publish',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing publish payload'));
      }
      final designRaw = data['design'];
      final designMap = designRaw is Map<String, dynamic> ? designRaw : data;
      final pct = (data['commissionPct'] is num)
          ? (data['commissionPct'] as num).round()
          : int.tryParse(data['commissionPct']?.toString() ?? '') ?? 10;
      return right((design: GarmentDesign.fromApi(designMap), commissionPct: pct));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Removes a design from the public showcase.
  Future<Either<AppException, GarmentDesign>> unpublishDesign(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.designs}/$id/unpublish',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing design payload'));
      }
      return right(GarmentDesign.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Deletes a design owned by the current user.
  Future<Either<AppException, Unit>> deleteDesign(String id) async {
    try {
      await _dio.delete<dynamic>(
        '${ApiEndpoints.designs}/$id',
        options: await _authOptions(),
      );
      return right(unit);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Uploads raw image bytes (e.g. bundled catalogue PNG) and returns URL.
  Future<Either<AppException, String>> uploadPrintBytes({
    required List<int> bytes,
    required String filename,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.upload,
        data: form,
        options: await _authOptionsMultipart(),
        onSendProgress: onSendProgress,
      );
      final data = response.data ?? const <String, dynamic>{};
      var url = data['url']?.toString() ??
          data['fileUrl']?.toString() ??
          data['path']?.toString() ??
          '';
      final key = data['key']?.toString() ?? '';
      if (url.startsWith('undefined')) {
        url = '';
      }
      if (url.isEmpty && key.isNotEmpty) {
        final base = (dotenv.env['CLOUDFLARE_R2_BASE_URL'] ?? '').trim();
        if (base.isNotEmpty) {
          final baseSanitized = base.replaceAll(RegExp(r'/+$'), '');
          final keySanitized = key.replaceAll(RegExp('^/+'), '');
          url = '$baseSanitized/$keySanitized';
        }
      }
      if (url.isEmpty) {
        return left(const ServerException(500, 'Upload response missing URL'));
      }
      return right(url);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Uploads an editor print image and returns the remote URL.
  Future<Either<AppException, String>> uploadPrintImage({
    required String filePath,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'print.jpg'),
      });
      // Do not set Content-Type manually — Dio must add the multipart boundary.
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.upload,
        data: form,
        options: await _authOptionsMultipart(),
        onSendProgress: onSendProgress,
      );
      final data = response.data ?? const <String, dynamic>{};
      var url = data['url']?.toString() ??
          data['fileUrl']?.toString() ??
          data['path']?.toString() ??
          '';
      final key = data['key']?.toString() ?? '';

      // Server may respond with `url: "undefined/uploads/..."` when
      // CLOUDFLARE_R2_BASE_URL isn't set. Prefer the returned `key` and build
      // the public URL using the app's env.
      if (url.startsWith('undefined')) {
        url = '';
      }
      if (url.isEmpty && key.isNotEmpty) {
        final base = (dotenv.env['CLOUDFLARE_R2_BASE_URL'] ?? '').trim();
        if (base.isNotEmpty) {
          final baseSanitized = base.replaceAll(RegExp(r'/+$'), '');
          final keySanitized = key.replaceAll(RegExp('^/+'), '');
          url = '$baseSanitized/$keySanitized';
        }
      }
      if (url.isEmpty) {
        return left(const ServerException(500, 'Upload response missing URL'));
      }
      return right(url);
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

  /// Authorization only — lets Dio set `multipart/form-data` + boundary.
  Future<Options> _authOptionsMultipart() async {
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
      final nestedError = body['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        message = nestedError['message'].toString();
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
