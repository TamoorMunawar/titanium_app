import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import 'auth_controller.dart';
import 'dashboard_controller.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(dioProvider));
});

class VehiclesPageState {
  const VehiclesPageState({
    required this.vehicles,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.searchQuery,
  });

  final List<Vehicle> vehicles;
  final int page;
  final int limit;
  final int total;
  final int pages;

  /// Empty when browsing the full list; non-empty when a chassis-number
  /// search is active (via the dedicated search endpoint).
  final String searchQuery;
}

class VehicleController extends AsyncNotifier<VehiclesPageState> {
  static const _pageSize = 10;

  /// Overridden by [SoldVehicleController] to scope the plain (non-search)
  /// listing to a different vehicle status.
  String get _listStatus => 'active';

  @override
  Future<VehiclesPageState> build() => _fetch(page: 1, query: '');

  Future<VehiclesPageState> _fetch({
    required int page,
    required String query,
  }) async {
    final repo = ref.read(vehicleRepositoryProvider);
    final result = query.isEmpty
        ? await repo.listVehicles(page: page, limit: _pageSize, status: _listStatus)
        : await repo.searchVehicles(query: query, page: page, limit: _pageSize);

    return VehiclesPageState(
      vehicles: result.vehicles,
      page: result.page,
      limit: result.limit,
      total: result.total,
      pages: result.pages,
      searchQuery: query,
    );
  }

  /// Applies a chassis-number search, resetting back to page 1. Pass an
  /// empty string to clear the filter and show all vehicles again.
  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: 1, query: query));
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current != null && current.page == page) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetch(page: page, query: current?.searchQuery ?? ''),
    );
  }

  Future<void> refresh() async {
    final current = state.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetch(page: current?.page ?? 1, query: current?.searchQuery ?? ''),
    );
  }

  /// Fetches the latest data for a single vehicle. Doesn't touch the cached
  /// page list — used to make sure edit forms open with fresh data.
  Future<Vehicle> fetchVehicle(String id) {
    return ref.read(vehicleRepositoryProvider).getVehicle(id);
  }

  Future<Vehicle> updateVehicle(
    String id, {
    String? color,
    String? location,
    String? status,
  }) async {
    final updated = await ref
        .read(vehicleRepositoryProvider)
        .updateVehicle(id, color: color, location: location, status: status);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        VehiclesPageState(
          vehicles: [
            for (final v in current.vehicles) v.id == id ? updated : v,
          ],
          page: current.page,
          limit: current.limit,
          total: current.total,
          pages: current.pages,
          searchQuery: current.searchQuery,
        ),
      );
    }
    return updated;
  }

  /// Marks a vehicle as sold. The main inventory listing only ever returns
  /// active vehicles (`GET /v2/api/inventory?status=active`), so — like
  /// [deleteVehicle] — the cached page drops the item locally rather than
  /// just patching its status in place. The Sold list and Dashboard stats
  /// are separate cached providers that don't otherwise know this happened,
  /// so they're invalidated to refetch next time either is viewed.
  Future<Vehicle> markAsSold(String id) async {
    final updated = await ref
        .read(vehicleRepositoryProvider)
        .updateVehicle(id, status: 'sold');

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        VehiclesPageState(
          vehicles: current.vehicles.where((v) => v.id != id).toList(),
          page: current.page,
          limit: current.limit,
          total: current.total - 1,
          pages: current.pages,
          searchQuery: current.searchQuery,
        ),
      );
    }
    ref.invalidate(soldVehicleControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    return updated;
  }

  Future<void> deleteVehicle(String id) async {
    await ref.read(vehicleRepositoryProvider).deleteVehicle(id);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        VehiclesPageState(
          vehicles: current.vehicles.where((v) => v.id != id).toList(),
          page: current.page,
          limit: current.limit,
          total: current.total - 1,
          pages: current.pages,
          searchQuery: current.searchQuery,
        ),
      );
    }
    ref.invalidate(dashboardControllerProvider);
  }
}

final vehicleControllerProvider =
    AsyncNotifierProvider<VehicleController, VehiclesPageState>(
  VehicleController.new,
);

/// Backs the "Sold Vehicles" screen reached from the Dashboard's Sold count
/// — same paging/search behavior as [VehicleController], just scoped to
/// `status=sold` instead of `active`.
class SoldVehicleController extends VehicleController {
  @override
  String get _listStatus => 'sold';
}

final soldVehicleControllerProvider =
    AsyncNotifierProvider<VehicleController, VehiclesPageState>(
  SoldVehicleController.new,
);
