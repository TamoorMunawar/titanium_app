import 'package:flutter_test/flutter_test.dart';

import 'package:titaniumapp/models/dashboard_summary.dart';

void main() {
  group('DashboardRecentInventoryItem.fromJson location handling', () {
    test('location null -> null', () {
      final item = DashboardRecentInventoryItem.fromJson({
        'id': 'inv-1',
        'type': 'Sedan',
        'model': 'Corolla',
        'description': 'GLi',
        'chassisNo': 'CH123',
        'color': 'White',
        'year': 2022,
        'location': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(item.location, isNull);
    });

    test('location as a plain string -> itself', () {
      final item = DashboardRecentInventoryItem.fromJson({
        'id': 'inv-2',
        'type': 'Sedan',
        'model': 'Corolla',
        'description': 'GLi',
        'chassisNo': 'CH124',
        'color': 'White',
        'year': 2022,
        'location': 'Main Yard',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(item.location, 'Main Yard');
    });

    test('location as a {id, name} map -> map name', () {
      final item = DashboardRecentInventoryItem.fromJson({
        'id': 'inv-3',
        'type': 'Sedan',
        'model': 'Corolla',
        'description': 'GLi',
        'chassisNo': 'CH125',
        'color': 'White',
        'year': 2022,
        'location': {'id': 'loc-1', 'name': 'Downtown Lot'},
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(item.location, 'Downtown Lot');
    });
  });

  group('DashboardSummary.fromJson', () {
    test('parses a minimal valid payload', () {
      final summary = DashboardSummary.fromJson({
        'details': {
          'stats': {
            'totalInventory': {'total': 10},
            'totalUsers': {'total': 5},
            'totalLocations': {'total': 2},
          },
          'inventoryByType': [],
          'recentActivity': [],
          'recentInventory': [
            {
              'id': 'inv-1',
              'type': 'Sedan',
              'model': 'Corolla',
              'description': 'GLi',
              'chassisNo': 'CH123',
              'color': 'White',
              'year': 2022,
              'location': {'id': 'loc-1', 'name': 'Downtown Lot'},
              'createdAt': '2026-01-01T00:00:00.000Z',
            },
          ],
          'lastLocation': null,
        },
      });

      expect(summary.totalInventory.total, 10);
      expect(summary.totalUsers.total, 5);
      expect(summary.totalLocations.total, 2);
      expect(summary.inventoryByType, isEmpty);
      expect(summary.recentActivity, isEmpty);
      expect(summary.recentInventory, hasLength(1));
      expect(summary.recentInventory.single.location, 'Downtown Lot');
      expect(summary.lastLocation, isNull);
    });
  });
}
