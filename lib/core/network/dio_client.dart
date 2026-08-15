import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'jwt_utils.dart';

const apiBaseUrl = 'https://titanum-app-fdy29.ondigitalocean.app';

class AuthHeaderInterceptor extends Interceptor {
  AuthHeaderInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      final expiry = decodeJwtExpiry(token);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        // Token has passed its 24h expiry — drop it locally rather than
        // sending a request we know the server will reject. The resulting
        // unauthenticated request 401s, which SessionExpiryInterceptor turns
        // into a logout.
        await _tokenStorage.clearSession();
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

/// Watches for `401 Unauthorized` responses (expired/invalid token) and
/// clears the stored session so the app can react by returning to the
/// login screen. Ignores the login endpoint itself — a wrong-password 401
/// there is a normal login failure, not an expired session.
class SessionExpiryInterceptor extends Interceptor {
  SessionExpiryInterceptor(this._tokenStorage, {required this.onSessionExpired});

  final TokenStorage _tokenStorage;
  final void Function() onSessionExpired;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status == 401 && !path.contains('/auth/login')) {
      await _tokenStorage.clearSession();
      onSessionExpired();
    }
    handler.next(err);
  }
}

/// Normalizes the API's `{code, message, details}` error envelope into an
/// [ApiException] so callers only ever deal with one exception type.
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: ApiException(
            code: (data['code'] as num?)?.toInt() ??
                err.response?.statusCode ??
                -1,
            message: (data['message'] as String?) ?? 'Something went wrong.',
            details: data['details'],
          ),
        ),
      );
      return;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(
          code: err.response?.statusCode ?? -1,
          message: err.message ?? 'Something went wrong.',
        ),
      ),
    );
  }
}

Dio buildDioClient(
  TokenStorage tokenStorage, {
  required void Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthHeaderInterceptor(tokenStorage),
    SessionExpiryInterceptor(tokenStorage, onSessionExpired: onSessionExpired),
    ApiErrorInterceptor(),
    LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ),
  ]);

  return dio;
}
