import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/orders/models/order.dart';
import 'package:lolipants/features/orders/models/order_estimate.dart';
import 'package:lolipants/features/orders/models/order_quote.dart';
import 'package:lolipants/features/orders/models/tailor_quote_option.dart';
import 'package:lolipants/features/orders/models/quote_negotiation.dart';
import 'package:lolipants/features/orders/models/accessory_order_quote.dart';
import 'package:lolipants/features/orders/models/wedding_order_quote.dart';

/// API-backed repository for customer orders.
class OrdersRepository {
  /// Creates the repository.
  OrdersRepository({
    required Dio dio,
    required AuthLocalStorage storage,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Loads all orders for the current authenticated user.
  Future<Either<AppException, List<Order>>> getMyOrders() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.orders,
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final orders = items
          .whereType<Map<String, dynamic>>()
          .map(Order.fromApi)
          .toList(growable: false);
      return right(orders);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Loads a single order by id.
  Future<Either<AppException, Order>> getOrderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/$id',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Cancels a customer order.
  Future<Either<AppException, void>> cancelOrder(String id) async {
    try {
      await _dio.delete<void>(
        '${ApiEndpoints.orders}/$id',
        options: await _authOptions(),
      );
      return right(null);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Fetches a garment price estimate band (no delivery location required).
  Future<Either<AppException, OrderEstimate>> getEstimate({
    required String garmentType,
    required String fabricQuality,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.ordersEstimate,
        queryParameters: {
          'garmentType': garmentType,
          'fabricQuality': fabricQuality,
        },
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing estimate payload'));
      }
      return right(OrderEstimate.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Compares quotes from multiple tailors near delivery coordinates.
  Future<Either<AppException, List<TailorQuoteOption>>> compareQuotes({
    required String designId,
    required String city,
    required double deliveryLat,
    required double deliveryLng,
    int limit = 5,
    List<String> accessoryIds = const [],
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.ordersQuotesCompare,
        queryParameters: {
          'designId': designId,
          'city': city,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          'limit': limit,
          if (accessoryIds.isNotEmpty) 'accessoryIds': accessoryIds.join(','),
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing compare payload'));
      }
      final quotesRaw = data['quotes'];
      final quotes = quotesRaw is List
          ? quotesRaw
              .whereType<Map<String, dynamic>>()
              .map(TailorQuoteOption.fromApi)
              .toList(growable: false)
          : const <TailorQuoteOption>[];
      return right(quotes);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Fetches a server-authoritative price quote for [designId] at delivery coords.
  Future<Either<AppException, OrderQuote>> getQuote({
    required String designId,
    required String city,
    required double deliveryLat,
    required double deliveryLng,
    List<String> accessoryIds = const [],
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.orders}/quote',
        queryParameters: {
          'designId': designId,
          'city': city,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          if (accessoryIds.isNotEmpty) 'accessoryIds': accessoryIds.join(','),
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing quote payload'));
      }
      return right(OrderQuote.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Wedding dress quote (`GET /orders/wedding-quote`).
  Future<Either<AppException, WeddingOrderQuote>> getWeddingQuote({
    required String dressId,
    required String fulfillment,
    required int rentalDays,
    required String city,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.ordersWeddingQuote,
        queryParameters: {
          'dressId': dressId,
          'fulfillment': fulfillment,
          'rentalDays': rentalDays,
          'city': city,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing quote payload'));
      }
      return right(WeddingOrderQuote.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Accessory purchase quote (`GET /orders/accessory-quote`).
  Future<Either<AppException, AccessoryOrderQuote>> getAccessoryQuote({
    required String accessoryId,
    required String city,
    required double deliveryLat,
    required double deliveryLng,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.ordersAccessoryQuote,
        queryParameters: {
          'accessoryId': accessoryId,
          'city': city,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing quote payload'));
      }
      return right(AccessoryOrderQuote.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Places a standalone accessory purchase order.
  Future<Either<AppException, Order>> createAccessoryOrder({
    required String accessoryId,
    required String fulfillmentType,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    required double deliveryLat,
    required double deliveryLng,
    required String tailorId,
    required int basePrice,
    required int fabricFee,
    required int deliveryFee,
    required int accessoryFee,
    required int totalPrice,
    String? deliveryNotes,
    String? idempotencyKey,
  }) async {
    try {
      final key = idempotencyKey ??
          'accessory_${DateTime.now().millisecondsSinceEpoch}_$accessoryId';
      final authOptions = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'accessoryId': accessoryId,
          'fulfillmentType': fulfillmentType,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': deliveryCity,
          'deliveryPhone': deliveryPhone,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          'tailorId': tailorId,
          'basePrice': basePrice,
          'fabricFee': fabricFee,
          'deliveryFee': deliveryFee,
          'accessoryFee': accessoryFee,
          'totalPrice': totalPrice,
          'deliveryNotes': deliveryNotes,
        },
        options: authOptions.copyWith(
          headers: {
            ...?(authOptions.headers),
            'X-Idempotency-Key': key,
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Places a wedding rent or purchase order.
  Future<Either<AppException, Order>> createWeddingOrder({
    required String weddingDressId,
    required String fulfillmentType,
    required String fulfillment,
    required int rentalDays,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    required double deliveryLat,
    required double deliveryLng,
    required String tailorId,
    required int basePrice,
    required int fabricFee,
    required int deliveryFee,
    required int totalPrice,
    String? deliveryNotes,
    String? idempotencyKey,
  }) async {
    try {
      final key = idempotencyKey ??
          'wedding_${DateTime.now().millisecondsSinceEpoch}_$weddingDressId';
      final authOptions = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'weddingDressId': weddingDressId,
          'fulfillmentType': fulfillmentType,
          'fulfillment': fulfillment,
          'rentalDays': rentalDays,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': deliveryCity,
          'deliveryPhone': deliveryPhone,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          'tailorId': tailorId,
          'basePrice': basePrice,
          'fabricFee': fabricFee,
          'deliveryFee': deliveryFee,
          'totalPrice': totalPrice,
          'deliveryNotes': deliveryNotes,
        },
        options: authOptions.copyWith(
          headers: {
            ...?(authOptions.headers),
            'X-Idempotency-Key': key,
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Creates a customer order from a saved design.
  ///
  /// Pass [idempotencyKey] to share the same key across retries or sibling
  /// requests (e.g. payment intent). When omitted a new key is generated.
  Future<Either<AppException, Order>> createOrder({
    required String designId,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    required double deliveryLat,
    required double deliveryLng,
    required String tailorId,
    required int basePrice,
    required int fabricFee,
    required int deliveryFee,
    required int totalPrice,
    int accessoryFee = 0,
    List<String> accessoryIds = const [],
    String? deliveryNotes,
    String? idempotencyKey,
    String? designerId,
    String? quoteLockToken,
  }) async {
    try {
      final key = idempotencyKey ??
          'order_${DateTime.now().millisecondsSinceEpoch}_$designId';
      final authOptions = await _authOptions();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.orders,
        data: {
          'designId': designId,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': deliveryCity,
          'deliveryPhone': deliveryPhone,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          'tailorId': tailorId,
          'basePrice': basePrice,
          'fabricFee': fabricFee,
          'deliveryFee': deliveryFee,
          'accessoryFee': accessoryFee,
          'totalPrice': totalPrice,
          'deliveryNotes': deliveryNotes,
          if (accessoryIds.isNotEmpty) 'accessoryIds': accessoryIds,
          if (designerId != null && designerId.isNotEmpty)
            'designerId': designerId,
          if (quoteLockToken != null && quoteLockToken.isNotEmpty)
            'quoteLockToken': quoteLockToken,
        },
        options: authOptions.copyWith(
          headers: {
            ...?(authOptions.headers),
            'X-Idempotency-Key': key,
          },
        ),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing order payload'));
      }
      return right(Order.fromApi(data));
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
    String? code;
    if (body is Map) {
      final nestedError = body['error'];
      if (nestedError is Map) {
        if (nestedError['message'] != null) {
          message = nestedError['message'].toString();
        }
        if (nestedError['code'] != null) {
          code = nestedError['code'].toString();
        }
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
    if (status == 401 || status == 403) {
      return AuthException(message);
    }
    if (status >= 500) {
      return ServerException(status, message, code: code);
    }
    if (status >= 400) {
      return ServerException(status, message, code: code);
    }
    return NetworkException(message);
  }

  /// Lists the customer's open quote negotiations.
  Future<Either<AppException, List<QuoteNegotiation>>> listMyNegotiations({
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.ordersQuoteNegotiations,
        queryParameters: status != null ? {'status': status} : null,
        options: await _authOptions(),
      );
      final raw = response.data?['negotiations'];
      final items = raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(QuoteNegotiation.fromApi)
              .toList(growable: false)
          : const <QuoteNegotiation>[];
      return right(items);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Tailor inbound price-request queue.
  Future<Either<AppException, List<QuoteNegotiation>>> listTailorNegotiations({
    String? status,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.ordersQuoteNegotiations}/tailor',
        queryParameters: status != null ? {'status': status} : null,
        options: await _authOptions(),
      );
      final raw = response.data?['negotiations'];
      final items = raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(QuoteNegotiation.fromApi)
              .toList(growable: false)
          : const <QuoteNegotiation>[];
      return right(items);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, QuoteNegotiationDetail>> getNegotiation(
    String id,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.ordersQuoteNegotiations}/$id',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing negotiation payload'));
      }
      return right(QuoteNegotiationDetail.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, QuoteNegotiationDetail>> createNegotiation({
    required String designId,
    required String tailorId,
    required int offeredTotal,
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryPhone,
    required double deliveryLat,
    required double deliveryLng,
    String? customerNote,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.ordersQuoteNegotiations,
        data: {
          'designId': designId,
          'tailorId': tailorId,
          'offeredTotal': offeredTotal,
          'deliveryAddress': deliveryAddress,
          'deliveryCity': deliveryCity,
          'deliveryPhone': deliveryPhone,
          'deliveryLat': deliveryLat,
          'deliveryLng': deliveryLng,
          if (customerNote != null && customerNote.isNotEmpty)
            'customerNote': customerNote,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing negotiation payload'));
      }
      return right(QuoteNegotiationDetail.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, QuoteNegotiationDetail>> sendNegotiationMessage({
    required String negotiationId,
    required String body,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.ordersQuoteNegotiations}/$negotiationId/messages',
        data: {'body': body},
        options: await _authOptions(),
      );
      return getNegotiation(negotiationId);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, QuoteNegotiationDetail>> acceptNegotiation(
    String id,
  ) async {
    return _negotiationAction(id, 'accept');
  }

  Future<Either<AppException, QuoteNegotiationDetail>> declineNegotiation(
    String id,
  ) async {
    return _negotiationAction(id, 'decline');
  }

  Future<Either<AppException, QuoteNegotiationDetail>> cancelNegotiation(
    String id,
  ) async {
    return _negotiationAction(id, 'cancel');
  }

  Future<Either<AppException, QuoteNegotiationDetail>> counterNegotiation({
    required String id,
    required int offeredTotal,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.ordersQuoteNegotiations}/$id/counter',
        data: {
          'offeredTotal': offeredTotal,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing negotiation payload'));
      }
      return right(QuoteNegotiationDetail.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  Future<Either<AppException, QuoteNegotiationDetail>> _negotiationAction(
    String id,
    String action,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.ordersQuoteNegotiations}/$id/$action',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing negotiation payload'));
      }
      return right(QuoteNegotiationDetail.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }
}
