import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../widgets/guest_login_required_dialog.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/vehicle_list_body.dart';
import 'dashboard_screen.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);

  Future<void> _openDashboard(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(authControllerProvider).user?.isGuest ?? false;
    if (isGuest) {
      final goToLogin = await showGuestLoginRequiredDialog(context);
      if (goToLogin) {
        await ref.read(authControllerProvider.notifier).logout();
      }
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_outlined,
                      color: _accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Vehicles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _openDashboard(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.dashboard_outlined,
                        color: _accentBlue,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.ios_share_outlined,
                      color: Colors.black54,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final confirmed = await showLogoutDialog(context);
                      if (confirmed) {
                        await ref.read(authControllerProvider.notifier).logout();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.black54,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: VehicleListBody(provider: vehicleControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}
