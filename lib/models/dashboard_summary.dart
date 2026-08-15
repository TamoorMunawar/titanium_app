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
      total: json['total'] as int? ?? 0,
      changePercent: (json['changePercent'] as num?)?.toDouble(),
      changeCount: json['changeCount'] as int?,
      soldCount: json['soldCount'] as int?,
      activeCount: json['activeCount'] as int?,
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
      type: json['type'] as String? ?? '',
      count: json['count'] as int? ?? 0,
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
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      action: json['action'] as String? ?? '',
      actorName: json['actorName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      timeAgo: json['timeAgo'] as String? ?? '',
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
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      model: json['model'] as String? ?? '',
      description: json['description'] as String? ?? '',
      chassisNo: json['chassisNo'] as String? ?? '',
      color: json['color'] as String? ?? '',
      year: json['year']?.toString() ?? '',
      location: json['location'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
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
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
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
      inventoryByType: (details['inventoryByType'] as List)
          .map((e) => InventoryTypeCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentActivity: (details['recentActivity'] as List)
          .map((e) => DashboardActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentInventory: (details['recentInventory'] as List)
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
