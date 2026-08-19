import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'splash_screen.dart';
import 'vehicles_screen.dart';

/// Root of the app's navigation: reactively shows Splash / Login / the
/// right dashboard based on [authControllerProvider]'s state, so a session
/// restore, a manual logout, and an automatic logout (expired token / 401)
/// all just work by updating that one piece of state.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    // Kick off the session check and a minimum-display timer in parallel,
    // so the branded splash doesn't just flash by even if the check
    // resolves instantly.
    final sessionCheck = ref.read(authControllerProvider.notifier).restoreSession();
    await Future.delayed(const Duration(seconds: 2));
    try {
      await sessionCheck;
    } catch (_) {
      // A corrupted/unreadable stored session shouldn't leave the user
      // stuck on the splash screen forever — fall through to login.
    }
    if (!mounted) return;
    setState(() => _checkingSession = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const SplashScreen();
    }

    final user = ref.watch(authControllerProvider).user;
    if (user == null) return const LoginScreen();
    return user.isSuperAdmin
        ? const AdminDashboardScreen()
        : const VehiclesScreen();
  }
}
