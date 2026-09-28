/// The dashboard API (`GET /v2/api/dashboard`) is inconsistent about whether
/// a "text" field comes back as a plain string or as an object — e.g. a
/// location as `{id, name}`, or a user as `{id, firstName, lastName}`. Every
/// `json[...] as String?` read in this file goes through this helper instead
/// of a direct cast, so a stray object never throws
/// `'_Map<String, dynamic>' is not a subtype of type 'String?'`. It
/// best-efforts a human-readable string out of common shapes and otherwise
/// returns null, letting callers apply their own `?? ''` fallback.
String? _stringFrom(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  if (value is Map) {
    for (final key in const [
      'name',
      'label',
      'title',
      'address',
      'fullName',
      'value',
    ]) {
      final candidate = value[key];
      if (candidate is String) return candidate;
    }
    final firstName = value['firstName'];
    final lastName = value['lastName'];
    if (firstName is String || lastName is String) {
      final joined = [
        if (firstName is String) firstName,
        if (lastName is String) lastName,
      ].join(' ').trim();
      if (joined.isNotEmpty) return joined;
    }
  }
  return null;
}

/// Companion to [_stringFrom] for numeric fields that have been seen coming
/// back as numeric strings (or missing) rather than JSON numbers.
int? _intFrom(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Companion to [_intFrom] for the file's `double` reads.
double? _doubleFrom(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class DashboardStat {
  const DashboardStat({
    required this.total,
    this.changePercent,
    this.changeCount,
    this.soldCount,
    this.activeCount,
  });

  factory DashboardStat.fromJson(Map<String, dynamic> json) {
    return DashboardStat(
      total: _intFrom(json['total']) ?? 0,
      changePercent: _doubleFrom(json['changePercent']),
      changeCount: _intFrom(json['changeCount']),
      soldCount: _intFrom(json['soldCount']),
      activeCount: _intFrom(json['activeCount']),
    );
  }

  final int total;
  final double? changePercent;
  final int? changeCount;

  /// Only populated on the Total Inventory stat, breaking `total` down by
  /// vehicle status.
  final int? soldCount;
  final int? activeCount;

  /// e.g. "+4.2%" or "+2", or null if there's nothing to show.
  String? get trendLabel {
    if (changePercent != null) {
      final percent = changePercent!;
      final formatted = percent == percent.roundToDouble()
          ? percent.toStringAsFixed(0)
          : percent.toStringAsFixed(1);
      return '${percent >= 0 ? '+' : ''}$formatted%';
    }
    if (changeCount != null && changeCount != 0) {
      return '${changeCount! >= 0 ? '+' : ''}$changeCount';
    }
    return null;
  }
}

class InventoryTypeCount {
  const InventoryTypeCount({required this.type, required this.count});

  factory InventoryTypeCount.fromJson(Map<String, dynamic> json) {
    return InventoryTypeCount(
      type: _stringFrom(json['type']) ?? '',
      count: _intFrom(json['count']) ?? 0,
    );
  }

  final String type;
  final int count;
}

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.message,
    required this.action,
    required this.actorName,
    required this.createdAt,
    required this.timeAgo,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: _stringFrom(json['id']) ?? '',
      message: _stringFrom(json['message']) ?? '',
      action: _stringFrom(json['action']) ?? '',
      actorName: _stringFrom(json['actorName']) ?? '',
      createdAt: DateTime.tryParse(_stringFrom(json['createdAt']) ?? '') ??
          DateTime.now(),
      timeAgo: _stringFrom(json['timeAgo']) ?? '',
    );
  }

  final String id;
  final String message;
  final String action;
  final String actorName;
  final DateTime createdAt;
  final String timeAgo;
}

class DashboardRecentInventoryItem {
  const DashboardRecentInventoryItem({
    required this.id,
    required this.type,
    required this.model,
    required this.description,
    required this.chassisNo,
    required this.color,
    required this.year,
    required this.location,
    required this.createdAt,
  });

  factory DashboardRecentInventoryItem.fromJson(Map<String, dynamic> json) {
    return DashboardRecentInventoryItem(
      id: _stringFrom(json['id']) ?? '',
      type: _stringFrom(json['type']) ?? '',
      model: _stringFrom(json['model']) ?? '',
      description: _stringFrom(json['description']) ?? '',
      chassisNo: _stringFrom(json['chassisNo']) ?? '',
      color: _stringFrom(json['color']) ?? '',
      year: json['year']?.toString() ?? '',
      // The `location` field varies across endpoints: `null`, a plain name
      // string, or `{id, name}` once a real Location has been assigned (as
      // returned by `PUT /v2/api/inventory/:id`); `_stringFrom` covers all
      // three shapes.
      location: _stringFrom(json['location']),
      createdAt: DateTime.tryParse(_stringFrom(json['createdAt']) ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String type;
  final String model;
  final String description;
  final String chassisNo;
  final String color;
  final String year;
  final String? location;
  final DateTime createdAt;

  String get name => '$type $model'.trim();
}

class DashboardLastLocation {
  const DashboardLastLocation({
    required this.address,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory DashboardLastLocation.fromJson(Map<String, dynamic> json) {
    return DashboardLastLocation(
      address: _stringFrom(json['address']) ?? '',
      lat: _doubleFrom(json['lat']) ?? 0,
      lng: _doubleFrom(json['lng']) ?? 0,
      updatedAt: DateTime.tryParse(_stringFrom(json['updatedAt']) ?? '') ??
          DateTime.now(),
    );
  }

  final String address;
  final double lat;
  final double lng;
  final DateTime updatedAt;
}

class DashboardSummary {
  const DashboardSummary({
    required this.totalInventory,
    required this.totalUsers,
    required this.totalLocations,
    required this.inventoryByType,
    required this.recentActivity,
    required this.recentInventory,
    required this.lastLocation,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    final stats = details['stats'] as Map<String, dynamic>;
    final lastLocationJson = details['lastLocation'] as Map<String, dynamic>?;

    return DashboardSummary(
      totalInventory: DashboardStat.fromJson(
        stats['totalInventory'] as Map<String, dynamic>,
      ),
      totalUsers: DashboardStat.fromJson(
        stats['totalUsers'] as Map<String, dynamic>,
      ),
      totalLocations: DashboardStat.fromJson(
        stats['totalLocations'] as Map<String, dynamic>,
      ),
      inventoryByType: (details['inventoryByType'] as List? ?? [])
          .map((e) => InventoryTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivity: (details['recentActivity'] as List? ?? [])
          .map((e) => DashboardActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentInventory: (details['recentInventory'] as List? ?? [])
          .map((e) => DashboardRecentInventoryItem.fromJson(
                e as Map<String, dynamic>,
              ))
          .toList(),
      lastLocation: lastLocationJson == null
          ? null
          : DashboardLastLocation.fromJson(lastLocationJson),
    );
  }

  final DashboardStat totalInventory;
  final DashboardStat totalUsers;
  final DashboardStat totalLocations;
  final List<InventoryTypeCount> inventoryByType;
  final List<DashboardActivity> recentActivity;
  final List<DashboardRecentInventoryItem> recentInventory;
  final DashboardLastLocation? lastLocation;
}
