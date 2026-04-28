import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' show Either, left, right;
import 'package:lolipants/core/errors/app_exception.dart';
import 'package:lolipants/core/network/api_endpoints.dart';
import 'package:lolipants/features/auth/data/auth_local_storage.dart';
import 'package:lolipants/features/community/models/comment.dart';
import 'package:lolipants/features/community/models/post.dart';

/// Paginated page of posts returned by [PostsRepository.getFeed].
class FeedPage {
  /// Creates a feed page.
  const FeedPage({required this.posts, required this.nextCursor});

  /// Posts in this page.
  final List<Post> posts;

  /// Cursor for the next page, or null if end of feed.
  final String? nextCursor;
}

/// Server reply for a reaction toggle.
class ReactionResult {
  /// Creates a reaction result.
  const ReactionResult({
    required this.postId,
    required this.currentUserReaction,
    required this.reactionCount,
  });

  /// Target post id.
  final String postId;

  /// Viewer's active reaction after the toggle, or null if cleared.
  final ReactionType? currentUserReaction;

  /// New total reaction count.
  final int reactionCount;
}

/// Repository for community posts + reactions + comments.
class PostsRepository {
  /// Creates the repository.
  PostsRepository({required Dio dio, required AuthLocalStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final AuthLocalStorage _storage;

  /// Fetches one page of the feed.
  Future<Either<AppException, FeedPage>> getFeed({
    String? tag,
    String? cursor,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posts,
        queryParameters: {
          if (tag != null && tag.isNotEmpty) 'tag': tag,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'pageSize': pageSize,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing feed payload'));
      }
      final raw = data['posts'];
      final list = raw is List ? raw : const <dynamic>[];
      final posts = list
          .whereType<Map<String, dynamic>>()
          .map(Post.fromApi)
          .toList(growable: false);
      return right(
        FeedPage(
          posts: posts,
          nextCursor: data['nextCursor']?.toString(),
        ),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Loads a single post by id.
  Future<Either<AppException, Post>> getPost(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiEndpoints.posts}/$id',
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing post payload'));
      }
      return right(Post.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Creates a new post.
  Future<Either<AppException, Post>> createPost({
    required String body,
    List<String> imageUrls = const [],
    List<String> tags = const [],
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posts,
        data: {
          'body': body,
          'imageUrls': imageUrls,
          'tags': tags,
        },
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing post payload'));
      }
      return right(Post.fromApi(data));
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Toggles a reaction. Sending the same [type] twice removes the reaction.
  Future<Either<AppException, ReactionResult>> toggleReaction({
    required String postId,
    required ReactionType type,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.posts}/$postId/reactions',
        data: {'type': reactionTypeToString(type)},
        options: await _authOptions(),
      );
      final data = response.data ?? const <String, dynamic>{};
      return right(
        ReactionResult(
          postId: data['postId']?.toString() ?? postId,
          currentUserReaction: reactionTypeFromString(
            data['currentUserReaction']?.toString(),
          ),
          reactionCount: (data['reactionCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Lists comments for a post.
  Future<Either<AppException, List<PostComment>>> getComments(
    String postId,
  ) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '${ApiEndpoints.posts}/$postId/comments',
        options: await _authOptions(),
      );
      final items = response.data ?? const <dynamic>[];
      final comments = items
          .whereType<Map<String, dynamic>>()
          .map(PostComment.fromApi)
          .toList(growable: false);
      return right(comments);
    } on DioException catch (e) {
      return left(_mapDio(e));
    } on Exception {
      return left(const UnknownException());
    }
  }

  /// Creates a comment on a post.
  Future<Either<AppException, PostComment>> addComment({
    required String postId,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.posts}/$postId/comments',
        data: {'body': body},
        options: await _authOptions(),
      );
      final data = response.data;
      if (data == null) {
        return left(const ServerException(500, 'Missing comment payload'));
      }
      return right(PostComment.fromApi(data));
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
