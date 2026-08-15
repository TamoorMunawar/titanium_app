class LocationRecord {
  const LocationRecord({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationRecord copyWith({String? name}) {
    return LocationRecord(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
