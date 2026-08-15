import 'location_record.dart';

class LocationListResult {
  const LocationListResult({
    required this.locations,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory LocationListResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    return LocationListResult(
      locations: (details['locations'] as List)
          .map((e) => LocationRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: details['page'] as int? ?? 1,
      limit: details['limit'] as int? ?? 10,
      total: details['total'] as int? ?? 0,
      pages: details['pages'] as int? ?? 1,
    );
  }

  final List<LocationRecord> locations;
  final int page;
  final int limit;
  final int total;
  final int pages;
}
