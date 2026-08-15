import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';
import 'auth_controller.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    return ref.read(dashboardRepositoryProvider).getSummary();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).getSummary(),
    );
  }
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
  DashboardController.new,
);
