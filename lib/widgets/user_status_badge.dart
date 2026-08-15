import 'package:flutter/material.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? const Color(0xFF1FA76A) : const Color(0xFFDC2626);
    final label = active ? 'Active' : 'Inactive';

    return Row(
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
    );
  }
}
