import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    late final String label;

    switch (status) {
      case VehicleStatus.active:
        background = const Color(0xFFE6F7ED);
        foreground = const Color(0xFF1FA76A);
        label = 'Active';
      case VehicleStatus.inTransit:
        background = const Color(0xFFFFF4E5);
        foreground = const Color(0xFFD97706);
        label = 'In transit';
      case VehicleStatus.inactive:
        background = const Color(0xFFFDEAEA);
        foreground = const Color(0xFFDC2626);
        label = 'Inactive';
      case VehicleStatus.sold:
        background = const Color(0xFFE9EAEE);
        foreground = const Color(0xFF6B7280);
        label = 'Sold';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: foreground, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
