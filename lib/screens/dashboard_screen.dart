import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/dashboard_controller.dart';
import 'dashboard_home_tab.dart';

/// Standalone, pushable wrapper around [DashboardHomeTab] — used on the
/// User side, which doesn't have a persistent tab bar like the Admin
/// dashboard does.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _didInvalidate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pushed fresh each time from the Vehicles screen, so force a refetch
    // rather than showing whatever was last cached. Can't do this in
    // initState — the ProviderScope isn't reachable until after it
    // completes — so it's guarded to run only once here instead.
    if (!_didInvalidate) {
      _didInvalidate = true;
      ref.invalidate(dashboardControllerProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: DashboardHomeTab(showBackButton: true)),
    );
  }
}
