import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/vehicle_controller.dart';
import 'dashboard_home_tab.dart';
import 'inventory_tab.dart';
import 'locations_tab.dart';
import 'upload_tab.dart';
import 'users_tab.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _navIndex = 0;

  List<Widget> get _tabs => [
        DashboardHomeTab(onViewInventory: () => _switchTab(1)),
        const InventoryTab(),
        UploadTab(onViewInventory: () => _switchTab(1)),
        const UsersTab(),
        const LocationsTab(),
      ];

  /// Switches tabs and invalidates that tab's data provider, so the tab
  /// bar always shows fresh data instead of whatever was last cached —
  /// the tabs stay mounted in the [IndexedStack] below, so without this
  /// they'd never naturally refetch on their own.
  void _switchTab(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        ref.invalidate(dashboardControllerProvider);
      case 1:
        ref.invalidate(vehicleControllerProvider);
      case 3:
        ref.invalidate(userControllerProvider);
      case 4:
        ref.invalidate(locationControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _navIndex, children: _tabs),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEBECF2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: _navIndex == 0,
                onTap: () => _switchTab(0),
              ),
              _NavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                selected: _navIndex == 1,
                onTap: () => _switchTab(1),
              ),
              _NavItem(
                icon: Icons.upload_outlined,
                label: 'Upload',
                selected: _navIndex == 2,
                onTap: () => _switchTab(2),
              ),
              _NavItem(
                icon: Icons.people_outline,
                label: 'Users',
                selected: _navIndex == 3,
                onTap: () => _switchTab(3),
              ),
              _NavItem(
                icon: Icons.location_on_outlined,
                label: 'Locations',
                selected: _navIndex == 4,
                onTap: () => _switchTab(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    final color = selected ? _accentBlue : Colors.black45;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF0FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
