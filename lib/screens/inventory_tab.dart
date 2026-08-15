import 'package:flutter/material.dart';

import '../controllers/vehicle_controller.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/vehicle_list_body.dart';

/// Admin-side vehicle inventory browser — shows the same live
/// `/v2/api/inventory` data (and chassis-number search) as the User-side
/// Vehicles screen.
class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(title: 'Inventory'),
        Expanded(
          child: VehicleListBody(provider: vehicleControllerProvider),
        ),
      ],
    );
  }
}
