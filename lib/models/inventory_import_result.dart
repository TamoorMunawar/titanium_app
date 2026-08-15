class InventoryImportResult {
  const InventoryImportResult({
    required this.totalRows,
    required this.inserted,
    required this.updated,
    required this.failed,
  });

  factory InventoryImportResult.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>;
    return InventoryImportResult(
      totalRows: details['totalRows'] as int? ?? 0,
      inserted: details['inserted'] as int? ?? 0,
      updated: details['updated'] as int? ?? 0,
      failed: List<dynamic>.from(details['failed'] as List? ?? const []),
    );
  }

  final int totalRows;
  final int inserted;
  final int updated;
  final List<dynamic> failed;
}
