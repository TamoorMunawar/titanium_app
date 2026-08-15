import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/app_user.dart';
import '../models/create_user_request.dart';
import '../models/update_user_request.dart';
import '../models/user_list_result.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  static const _usersPath = '/v2/api/users';

  Future<UserListResult> listUsers({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _usersPath,
        queryParameters: {'page': page, 'limit': limit},
      );
      return UserListResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<AppUser> createUser(CreateUserRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _usersPath,
        data: request.toJson(),
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return AppUser.fromJson(details['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<AppUser> updateUser(String id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_usersPath/$id',
        data: request.toJson(),
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return AppUser.fromJson(details['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('$_usersPath/$id');
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      code: -1,
      message: e.message ?? 'Network error. Please try again.',
    );
  }
}
