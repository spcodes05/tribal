import 'package:dio/dio.dart';
import 'api_config.dart';
import 'token_storage.dart';

/// Central Dio instance for all backend calls.
///
/// Responsibilities:
///   - Prefixes every request with [ApiConfig.baseUrl]
///   - Attaches `Authorization: Bearer <access_token>` automatically
///   - On a 401 response, tries once to refresh the access token via
///     `/api/token/refresh/` and retries the original request.
///   - If refresh also fails, clears stored tokens (caller should then
///     redirect to login — see [ApiException.isAuthError]).
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isRefreshCall = error.requestOptions.path == ApiConfig.tokenRefresh;

          if (isUnauthorized && !isRefreshCall) {
            final refreshed = await _tryRefreshToken();
            if (refreshed != null) {
              // Retry the original request with the new token.
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // Fall through to clearing tokens below.
              }
            }
            // Refresh failed (or retry failed) — wipe tokens so the app
            // can detect logged-out state and redirect to login.
            await TokenStorage.instance.clear();
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<String?> _tryRefreshToken() async {
    final refreshToken = await TokenStorage.instance.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      // Use a bare Dio (no interceptors) to avoid recursive auth headers.
      final response = await Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)).post(
        ApiConfig.tokenRefresh,
        data: {'refresh': refreshToken},
      );
      final newAccess = response.data['access'] as String?;
      if (newAccess != null) {
        await TokenStorage.instance.saveAccessToken(newAccess);
        return newAccess;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Normalised exception thrown by every service method in this app.
///
/// Wraps Dio's messy [DioException] into a single, predictable shape so
/// controllers never need to know about Dio directly.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Builds an [ApiException] from a caught [DioException], extracting
  /// DRF's typical error shapes:
  ///   { "detail": "..." }
  ///   { "field_name": ["error 1", "error 2"] }
  factory ApiException.fromDio(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException(
        'Could not reach the server. Check your connection and that the backend is running.',
        statusCode: statusCode,
      );
    }

    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) {
        return ApiException(
          data['detail'] as String,
          statusCode: statusCode,
          code: data['code'] as String?,
        );
      }
      // First field-level error DRF returns, e.g. {"email": ["already exists"]}.
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return ApiException('${entry.key}: ${value.first}', statusCode: statusCode);
        }
        if (value is String) {
          return ApiException('${entry.key}: $value', statusCode: statusCode);
        }
      }
    }

    return ApiException('Something went wrong. Please try again.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
