import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/create_location_request.dart';
import '../models/location_list_result.dart';
import '../models/location_record.dart';

class LocationRepository {
  LocationRepository(this._dio);

  final Dio _dio;

  static const _locationsPath = '/v2/api/locations';

  Future<LocationListResult> listLocations({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _locationsPath,
        queryParameters: {'page': page, 'limit': limit},
      );
      return LocationListResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<LocationRecord> createLocation(CreateLocationRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _locationsPath,
        data: request.toJson(),
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return LocationRecord.fromJson(details['location'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<LocationRecord> updateLocation(String id, String name) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_locationsPath/$id',
        data: CreateLocationRequest(name: name).toJson(),
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return LocationRecord.fromJson(details['location'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('$_locationsPath/$id');
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
