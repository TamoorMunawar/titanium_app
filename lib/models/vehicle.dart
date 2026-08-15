enum VehicleStatus { active, inTransit, inactive, sold }

VehicleStatus _statusFromJson(String? raw) {
  switch (raw) {
    case 'sold':
      return VehicleStatus.sold;
    case 'inactive':
      return VehicleStatus.inactive;
    case 'inTransit':
    case 'in_transit':
      return VehicleStatus.inTransit;
    default:
      return VehicleStatus.active;
  }
}

class Vehicle {
  const Vehicle({
    this.id = '',
    required this.name,
    required this.vin,
    required this.status,
    required this.make,
    required this.model,
    required this.variant,
    required this.manufacturingYear,
    required this.color,
    required this.currentLocation,
    required this.lastUpdated,
    required this.updatedBy,
    this.registrationNumber,
    this.ownerName,
    this.phoneNumber,
    this.cnic,
    this.address,
    this.engineNumber,
    this.engineCapacity,
    this.fuelType,
    this.transmission,
    this.registrationDate,
    this.registrationCity,
    this.registrationStatus,
    this.insuranceCompany,
    this.policyNumber,
    this.insuranceExpiry,
    this.notes = '',
  });

  /// Maps a row from `GET /v2/api/inventory` (chassis/type/model/description
  /// style fields) onto this vehicle model. The API doesn't provide
  /// ownership/registration/insurance data, so those stay unset.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final model = json['model'] as String? ?? '';
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');

    return Vehicle(
      id: json['id'] as String? ?? '',
      name: '$type $model'.trim(),
      vin: json['chassisNo'] as String? ?? '',
      status: _statusFromJson(json['status'] as String?),
      make: type,
      model: model,
      variant: json['description'] as String? ?? '',
      manufacturingYear: json['year']?.toString() ?? '',
      color: json['color'] as String? ?? '',
      currentLocation: _locationNameFrom(json['location']) ?? 'Unassigned',
      lastUpdated: updatedAt != null ? _formatDate(updatedAt) : '',
      updatedBy: json['updatedBy'] as String? ?? '',
    );
  }

  /// The `location` field varies across endpoints: `null`, a plain name
  /// string, or `{id, name}` once a real Location has been assigned (as
  /// returned by `PUT /v2/api/inventory/:id`).
  static String? _locationNameFrom(Object? location) {
    if (location == null) return null;
    if (location is String) return location;
    if (location is Map<String, dynamic>) return location['name'] as String?;
    return null;
  }

  final String id;
  final String name;
  final String vin;
  final String? registrationNumber;
  final VehicleStatus status;

  final String make;
  final String model;
  final String variant;
  final String manufacturingYear;
  final String color;

  final String? ownerName;
  final String? phoneNumber;
  final String? cnic;
  final String? address;

  final String? engineNumber;
  final String? engineCapacity;
  final String? fuelType;
  final String? transmission;

  final String? registrationDate;
  final String? registrationCity;
  final String? registrationStatus;

  final String? insuranceCompany;
  final String? policyNumber;
  final String? insuranceExpiry;

  final String notes;

  final String currentLocation;
  final String lastUpdated;
  final String updatedBy;

  Vehicle copyWith({
    VehicleStatus? status,
    String? registrationNumber,
    String? make,
    String? model,
    String? variant,
    String? manufacturingYear,
    String? color,
    String? ownerName,
    String? phoneNumber,
    String? cnic,
    String? address,
    String? engineNumber,
    String? engineCapacity,
    String? fuelType,
    String? transmission,
    String? registrationDate,
    String? registrationCity,
    String? registrationStatus,
    String? insuranceCompany,
    String? policyNumber,
    String? insuranceExpiry,
    String? notes,
    String? currentLocation,
    String? lastUpdated,
    String? updatedBy,
  }) {
    return Vehicle(
      id: id,
      name: name,
      vin: vin,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      status: status ?? this.status,
      make: make ?? this.make,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      color: color ?? this.color,
      ownerName: ownerName ?? this.ownerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnic: cnic ?? this.cnic,
      address: address ?? this.address,
      engineNumber: engineNumber ?? this.engineNumber,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      fuelType: fuelType ?? this.fuelType,
      transmission: transmission ?? this.transmission,
      registrationDate: registrationDate ?? this.registrationDate,
      registrationCity: registrationCity ?? this.registrationCity,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      policyNumber: policyNumber ?? this.policyNumber,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      notes: notes ?? this.notes,
      currentLocation: currentLocation ?? this.currentLocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
