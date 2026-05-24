import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';

class AiRenderQuota {
  const AiRenderQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    this.resetsAt,
  });

  final int limit;
  final int used;
  final int remaining;
  final DateTime? resetsAt;

  factory AiRenderQuota.fromJson(Map<String, dynamic> json) {
    final resetsRaw = json['resetsAt']?.toString();
    DateTime? resetsAt;
    if (resetsRaw != null && resetsRaw.isNotEmpty) {
      resetsAt = DateTime.tryParse(resetsRaw);
    }
    return AiRenderQuota(
      limit: (json['limit'] is num) ? (json['limit'] as num).toInt() : 3,
      used: (json['used'] is num) ? (json['used'] as num).toInt() : 0,
      remaining:
          (json['remaining'] is num) ? (json['remaining'] as num).toInt() : 0,
      resetsAt: resetsAt,
    );
  }

  bool get canRender => remaining > 0;
}

class RenderPreviewJob {
  const RenderPreviewJob({
    required this.jobId,
    required this.status,
    required this.providerStatus,
    required this.progress,
    required this.artifacts,
    this.error,
  });

  final String jobId;
  final String status;
  final String providerStatus;
  final double progress;
  final Map<String, String> artifacts;
  final String? error;
}

class RenderPreviewRepository {
  RenderPreviewRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppException, AiRenderQuota>> getQuota() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.aiDesignRender}/quota',
      );
      return right(
        AiRenderQuota.fromJson(response.data ?? const <String, dynamic>{}),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, RenderPreviewJob>> startRender({
    required String designId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.aiDesignRender,
        data: {'designId': designId},
      );
      return right(_parse(response.data ?? const <String, dynamic>{}));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, RenderPreviewJob>> getRenderStatus({
    required String jobId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.aiDesignRender}/$jobId',
        options: Options(
          // Poll may block while Gemini/OpenAI image generation runs on the worker.
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      return right(_parse(response.data ?? const <String, dynamic>{}));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  RenderPreviewJob _parse(Map<String, dynamic> body) {
    final artifactsRaw = body['artifacts'];
    final artifacts = <String, String>{};
    if (artifactsRaw is Map) {
      for (final entry in artifactsRaw.entries) {
        final value = entry.value;
        if (value is String && value.isNotEmpty) {
          artifacts[entry.key.toString()] = value;
        }
      }
    }
    return RenderPreviewJob(
      jobId: body['jobId']?.toString() ?? '',
      status: body['status']?.toString() ?? 'queued',
      providerStatus: body['providerStatus']?.toString() ?? 'queued',
      progress: (body['progress'] is num) ? (body['progress'] as num).toDouble() : 0,
      artifacts: artifacts,
      error: body['error']?.toString(),
    );
  }

  AppException _mapDio(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    var message = e.message ?? 'network';
    if (body is Map) {
      final err = body['error'];
      if (err is Map && err['message'] != null) {
        message = err['message'].toString();
      } else if (body['message'] != null) {
        message = body['message'].toString();
      } else if (body['error'] != null) {
        message = body['error'].toString();
      }
    }
    if (status >= 500) return ServerException(status, message);
    if (status >= 400) return ServerException(status, message);
    return NetworkException(message);
  }
}
