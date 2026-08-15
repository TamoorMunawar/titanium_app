import 'package:flutter/material.dart';

import '../controllers/vehicle_controller.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/vehicle_list_body.dart';

/// Reached by tapping the Sold count on the Dashboard's Total Inventory
/// card — same list/search UI as the main Vehicles screen, just scoped to
/// `status=sold` via [soldVehicleControllerProvider].
class SoldInventoryScreen extends StatelessWidget {
  const SoldInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppTopBar(title: 'Sold Vehicles', showBackButton: true),
            Expanded(
              child: VehicleListBody(
                provider: soldVehicleControllerProvider,
                listTitle: 'SOLD VEHICLES',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
