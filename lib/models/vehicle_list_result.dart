import 'vehicle.dart';

class VehicleListResult {
  const VehicleListResult({
    required this.vehicles,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory VehicleListResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    return VehicleListResult(
      vehicles: (details['items'] as List)
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: details['page'] as int? ?? 1,
      limit: details['limit'] as int? ?? 10,
      total: details['total'] as int? ?? 0,
      pages: details['pages'] as int? ?? 1,
    );
  }

  final List<Vehicle> vehicles;
  final int page;
  final int limit;
  final int total;
  final int pages;
}
