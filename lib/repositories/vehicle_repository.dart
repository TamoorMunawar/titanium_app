import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/vehicle.dart';
import '../models/vehicle_list_result.dart';

class VehicleRepository {
  VehicleRepository(this._dio);

  final Dio _dio;

  static const _inventoryPath = '/v2/api/inventory';
  static const _searchPath = '/v2/api/inventory/search';

  Future<VehicleListResult> listVehicles({
    int page = 1,
    int limit = 10,
    String status = 'active',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _inventoryPath,
        queryParameters: {'page': page, 'limit': limit, 'status': status},
      );
      return VehicleListResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Searches by chassis number (partial matches supported) via the
  /// dedicated `/v2/api/inventory/search` endpoint.
  Future<VehicleListResult> searchVehicles({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _searchPath,
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );
      return VehicleListResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Vehicle> getVehicle(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_inventoryPath/$id',
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return Vehicle.fromJson(details['item'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Vehicle> updateVehicle(
    String id, {
    String? color,
    String? location,
    String? status,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_inventoryPath/$id',
        data: {
          if (color != null) 'color': color,
          if (location != null) 'location': location,
          if (status != null) 'status': status,
        },
      );
      final details = response.data!['details'] as Map<String, dynamic>;
      return Vehicle.fromJson(details['item'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('$_inventoryPath/$id');
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
