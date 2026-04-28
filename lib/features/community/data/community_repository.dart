import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';

/// Lightweight consultation row model (the API shape varies a bit, so we keep
/// a flexible map here until a proper model is warranted).
class Consultation {
  /// Creates a consultation entry.
  const Consultation({
    required this.id,
    required this.userId,
    required this.garmentType,
    required this.description,
    required this.status,
    required this.createdAt,
    this.designerId,
    this.budgetMin,
    this.budgetMax,
  });

  /// Parses an API payload.
  factory Consultation.fromApi(Map<String, dynamic> json) {
    return Consultation(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      designerId: json['designer_id']?.toString() ??
          json['designerId']?.toString(),
      garmentType: json['garment_type']?.toString() ??
          json['garmentType']?.toString() ??
          'other',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      budgetMin: _asDouble(json['budget_min']) ??
          _asDouble(json['budgetMin']),
      budgetMax: _asDouble(json['budget_max']) ??
          _asDouble(json['budgetMax']),
    );
  }

  /// Consultation id.
  final String id;

  /// Owner user id.
  final String userId;

  /// Assigned designer user id (if any).
  final String? designerId;

  /// Requested garment type.
  final String garmentType;

  /// Free-text description.
  final String description;

  /// Current status ("open", "in_progress", "closed", ...).
  final String status;

  /// Submitted timestamp.
  final DateTime createdAt;

  /// Min budget (optional).
  final double? budgetMin;

  /// Max budget (optional).
  final double? budgetMax;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Repository for consultations API.
class CommunityRepository {
  /// Creates repository instance.
  CommunityRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

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

  /// Lists consultations owned by the current user (or assigned, when
  /// [role] == 'designer').
  Future<Either<AppException, List<Consultation>>> listConsultations({
    String role = 'mine',
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.community}/consultations',
        queryParameters: {'role': role},
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items
            .whereType<Map<String, dynamic>>()
            .map(Consultation.fromApi)
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Updates a consultation's status/description (and optionally assigns the
  /// current user as the designer).
  Future<Either<AppException, Consultation>> respondConsultation({
    required String id,
    String? status,
    String? description,
    bool assignSelf = false,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.community}/consultations/$id',
        data: {
          if (status != null) 'status': status,
          if (description != null) 'description': description,
          if (assignSelf) 'assignSelf': true,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing consultation payload'));
      }
      return right(Consultation.fromApi(data));
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
      final nested = body['error'];
      if (nested is Map && nested['message'] != null) {
        message = nested['message'].toString();
      } else {
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
