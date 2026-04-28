import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';

/// Server payment intent row.
class PaymentIntent {
  /// Creates an intent value object.
  const PaymentIntent({
    required this.reference,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
  });

  /// Server-generated reference, used to confirm + reconcile the payment.
  final String reference;

  /// Order this intent captures money for.
  final String orderId;

  /// Amount in [currency] minor units... actually whole QAR.
  final int amount;

  /// ISO 4217 currency code.
  final String currency;

  /// Server status, e.g. `requires_payment`.
  final String status;

  /// Parses a `POST /payments/intent` response.
  factory PaymentIntent.fromApi(Map<String, dynamic> json) {
    int asInt(Object? v) =>
        (v is num) ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    return PaymentIntent(
      reference: json['paymentReference']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: asInt(json['amount']),
      currency: json['currency']?.toString() ?? 'QAR',
      status: json['status']?.toString() ?? 'requires_payment',
    );
  }
}

/// API-backed repository for payments.
///
/// Real Tap SDK integration lives on top of [createIntent] — this layer
/// returns the server reference and then reconciliation is driven by the
/// Tap webhook (`POST /payments/webhook/tap`). For pre-launch testing a
/// dev-only [sandboxConfirm] call flips the transaction to `paid` without
/// contacting Tap; it is a 404 in production.
class PaymentsRepository {
  /// Creates the repository.
  PaymentsRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Asks the server to create (or reuse) a payment transaction for [orderId].
  Future<Either<AppException, PaymentIntent>> createIntent({
    required String orderId,
    String? idempotencyKey,
  }) async {
    try {
      final auth = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentIntent,
        data: {'orderId': orderId},
        options: auth.copyWith(
          headers: {
            ...?(auth.headers),
            if (idempotencyKey != null) 'X-Idempotency-Key': idempotencyKey,
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing intent payload'));
      }
      return right(PaymentIntent.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Captures a Tap charge server-side using the [tapToken] returned by the
  /// Tap Flutter SDK (or any first-party hosted card widget). Keeps the full
  /// charge create call behind our API so the secret never leaves the edge.
  Future<Either<AppException, void>> confirmWithToken({
    required String paymentReference,
    required String tapToken,
    String? idempotencyKey,
  }) async {
    try {
      final auth = await _authOptions();
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentConfirm,
        data: {
          'paymentReference': paymentReference,
          'tapToken': tapToken,
        },
        options: auth.copyWith(
          headers: {
            ...?(auth.headers),
            if (idempotencyKey != null) 'X-Idempotency-Key': idempotencyKey,
          },
        ),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Dev-only sandbox confirmation. The server enforces that the caller owns
  /// the underlying order and disables this route in production.
  Future<Either<AppException, void>> sandboxConfirm({
    required String paymentReference,
    bool fail = false,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentSimulate,
        data: {
          'paymentReference': paymentReference,
          'outcome': fail ? 'failed' : 'paid',
        },
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
      } else if (body['error'] != null) {
        message = body['error'].toString();
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
