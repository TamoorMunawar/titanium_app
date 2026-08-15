import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'logout_dialog.dart';

class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key, required this.title, this.showBackButton = false});

  final String title;

  /// Shows a back chevron before the title — for when this bar sits on a
  /// screen reached via push navigation rather than a persistent tab.
  final bool showBackButton;

  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBackButton ? 8 : 16, 12, 16, 0),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black87,
              ),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _accentBlue,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _fieldFill,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.black54,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _accentBlue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'SC',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
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
    );
  }
}
