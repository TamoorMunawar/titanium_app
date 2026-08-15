import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  static const _dashboardPath = '/v2/api/dashboard';

  Future<DashboardSummary> getSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_dashboardPath);
      return DashboardSummary.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        code: -1,
        message: e.message ?? 'Network error. Please try again.',
      );
    }
  }
}
