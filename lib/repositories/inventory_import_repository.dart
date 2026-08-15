import 'package:dio/dio.dart';

import '../core/network/api_exception.dart';
import '../models/inventory_import_result.dart';

class InventoryImportRepository {
  InventoryImportRepository(this._dio);

  final Dio _dio;

  static const _importPath = '/v2/api/inventory/import';

  Future<InventoryImportResult> importFile({
    required String filePath,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        _importPath,
        data: formData,
      );
      return InventoryImportResult.fromJson(response.data!);
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
