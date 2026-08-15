import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/auth/login_result.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  static const _loginPath = '/v2/api/auth/login';
  static const _guestLoginPath = '/v2/api/auth/guest';

  Future<LoginResult> login({
    required String email,
    required String password,
    required String usertype,
    double? lat,
    double? lng,
    String? address,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _loginPath,
        data: {
          'email': email,
          'password': password,
          'usertype': usertype,
          'address': address,
          'lat': lat,
          'lng': lng,
        },
      );
      return LoginResult.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        code: -1,
        message: e.message ?? 'Network error. Please try again.',
      );
    }
  }

  Future<LoginResult> guestLogin() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(_guestLoginPath);
      return LoginResult.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        code: -1,
        message: e.message ?? 'Network error. Please try again.',
      );
    }
  }
}
