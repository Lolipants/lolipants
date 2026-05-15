import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';

/// Thin wrapper around the admin dashboard endpoints. Every call returns the
/// raw JSON map / list so screens can render without an intermediate model
/// layer — the data surface across seven tabs is too broad to pre-model.
class AdminRepository {
  /// Creates the repository.
  AdminRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  Future<Either<AppException, List<Map<String, dynamic>>>> listUsers({
    String? role,
    bool? banned,
    String? search,
  }) {
    return _getList('/users', query: {
      if (role != null && role.isNotEmpty) 'role': role,
      if (banned != null) 'banned': banned ? 'true' : 'false',
      if (search != null && search.isNotEmpty) 'q': search,
    });
  }

  Future<Either<AppException, Map<String, dynamic>>> patchUser({
    required String id,
    String? role,
    List<String>? adminScopes,
    bool? banned,
  }) {
    return _patch('/users/$id', {
      if (role != null) 'role': role,
      if (adminScopes != null) 'adminScopes': adminScopes,
      if (banned != null) 'banned': banned,
    });
  }

  Future<Either<AppException, List<Map<String, dynamic>>>> listOrders({
    String? status,
  }) {
    return _getList('/orders', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<Either<AppException, Map<String, dynamic>>> patchOrder({
    required String id,
    String? status,
    String? tailorId,
    String? courierId,
    String? note,
  }) {
    return _patch('/orders/$id', {
      if (status != null) 'status': status,
      if (tailorId != null) 'tailorId': tailorId,
      if (courierId != null) 'courierId': courierId,
      if (note != null) 'note': note,
    });
  }

  Future<Either<AppException, List<Map<String, dynamic>>>> listPayouts({
    String? status,
  }) {
    return _getList('/payouts', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<Either<AppException, Map<String, dynamic>>> patchPayout({
    required String id,
    required String status,
    String? payoutReference,
    String? notes,
  }) {
    return _patch('/payouts/$id', {
      'status': status,
      if (payoutReference != null) 'payoutReference': payoutReference,
      if (notes != null) 'notes': notes,
    });
  }

  Future<Either<AppException, void>> hidePost(String id) =>
      _patchVoid('/moderation/posts/$id/hide');

  Future<Either<AppException, void>> hideDesign(String id) =>
      _patchVoid('/moderation/designs/$id/hide');

  Future<Either<AppException, void>> voidCommission(String id) async {
    try {
      await _dio.delete<dynamic>(
        '${ApiEndpoints.admin}/moderation/commissions/$id',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, List<Map<String, dynamic>>>> listCms(String resource) =>
      _getList('/cms/$resource');

  Future<Either<AppException, List<Map<String, dynamic>>>> listConfiguratorCms(
    String resource, {
    String? templateId,
    String? slotId,
  }) {
    return _getList(
      '/cms/configurator/$resource',
      query: {
        if (templateId != null && templateId.isNotEmpty) 'templateId': templateId,
        if (slotId != null && slotId.isNotEmpty) 'slotId': slotId,
      },
    );
  }

  Future<Either<AppException, Map<String, dynamic>>> createConfiguratorCms(
    String resource,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.admin}/cms/configurator/$resource',
        data: body,
        options: await _authOptions(),
      );
      return right(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, Map<String, dynamic>>> updateConfiguratorCms(
    String resource,
    String id,
    Map<String, dynamic> body,
  ) {
    return _patch('/cms/configurator/$resource/$id', body);
  }

  Future<Either<AppException, void>> deleteConfiguratorCms(
    String resource,
    String id,
  ) async {
    try {
      await _dio.delete<dynamic>(
        '${ApiEndpoints.admin}/cms/configurator/$resource/$id',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, Map<String, dynamic>>> createCms(
    String resource,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.admin}/cms/$resource',
        data: body,
        options: await _authOptions(),
      );
      return right(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, Map<String, dynamic>>> updateCms(
    String resource,
    String id,
    Map<String, dynamic> body,
  ) {
    return _patch('/cms/$resource/$id', body);
  }

  Future<Either<AppException, void>> deleteCms(String resource, String id) async {
    try {
      await _dio.delete<dynamic>(
        '${ApiEndpoints.admin}/cms/$resource/$id',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, List<Map<String, dynamic>>>> listComplaints({
    String? status,
  }) {
    return _getList('/complaints', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<Either<AppException, Map<String, dynamic>>> patchComplaint({
    required String id,
    required String status,
    String? resolution,
  }) {
    return _patch('/complaints/$id', {
      'status': status,
      if (resolution != null) 'resolution': resolution,
    });
  }

  /// Partner role requests (tailor / delivery intake).
  Future<Either<AppException, List<Map<String, dynamic>>>> listRoleRequests({
    String? status,
  }) {
    return _getList('/role-requests', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  /// Approve or reject a role request.
  Future<Either<AppException, Map<String, dynamic>>> patchRoleRequest({
    required String id,
    required String status,
    String? adminNote,
  }) {
    return _patch('/role-requests/$id', {
      'status': status,
      if (adminNote != null && adminNote.trim().isNotEmpty)
        'adminNote': adminNote.trim(),
    });
  }

  Future<Either<AppException, Map<String, dynamic>>> stats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.admin}/stats',
        options: await _authOptions(),
      );
      return right(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, List<Map<String, dynamic>>>> _getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.admin}$path',
        queryParameters: query,
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      return right(
        items.whereType<Map<String, dynamic>>().toList(growable: false),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, Map<String, dynamic>>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.admin}$path',
        data: body,
        options: await _authOptions(),
      );
      return right(response.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, void>> _patchVoid(String path) async {
    try {
      await _dio.patch<dynamic>(
        '${ApiEndpoints.admin}$path',
        options: await _authOptions(),
      );
      return right(null);
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
      } else if (body['message'] != null) {
        message = body['message'].toString();
      }
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
