class Location {
  const Location({required this.name, required this.createdOn});

  final String name;
  final String createdOn;
}

const sampleLocations = [
  Location(name: 'Warehouse A', createdOn: 'Mar 3, 2025'),
  Location(name: 'Warehouse B', createdOn: 'Apr 12, 2025'),
  Location(name: 'Downtown Store', createdOn: 'May 20, 2025'),
  Location(name: 'Airport Outlet', createdOn: 'Jun 8, 2025'),
  Location(name: 'Distribution Center', createdOn: 'Sep 15, 2025'),
  Location(name: 'Online Fulfillment', createdOn: 'Nov 1, 2025'),
  Location(name: 'Port Warehouse', createdOn: 'Jul 14, 2026'),
];
