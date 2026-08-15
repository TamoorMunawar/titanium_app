import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/create_location_request.dart';
import '../models/location_record.dart';
import '../repositories/location_repository.dart';
import 'auth_controller.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(dioProvider));
});

class LocationsPageState {
  const LocationsPageState({
    required this.locations,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  final List<LocationRecord> locations;
  final int page;
  final int limit;
  final int total;
  final int pages;
}

class LocationController extends AsyncNotifier<LocationsPageState> {
  static const _pageSize = 10;

  @override
  Future<LocationsPageState> build() => _fetch(page: 1);

  Future<LocationsPageState> _fetch({required int page}) async {
    final result = await ref
        .read(locationRepositoryProvider)
        .listLocations(page: page, limit: _pageSize);
    return LocationsPageState(
      locations: result.locations,
      page: result.page,
      limit: result.limit,
      total: result.total,
      pages: result.pages,
    );
  }

  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current != null && current.page == page) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: page));
  }

  Future<void> refresh() async {
    final page = state.value?.page ?? 1;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(page: page));
  }

  Future<LocationRecord> createLocation(String name) async {
    final created = await ref
        .read(locationRepositoryProvider)
        .createLocation(CreateLocationRequest(name: name));

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        LocationsPageState(
          locations: [created, ...current.locations],
          page: current.page,
          limit: current.limit,
          total: current.total + 1,
          pages: current.pages,
        ),
      );
    }
    return created;
  }

  Future<LocationRecord> updateLocation(String id, String name) async {
    final updated =
        await ref.read(locationRepositoryProvider).updateLocation(id, name);

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(
        LocationsPageState(
          locations: [
            for (final l in current.locations) l.id == id ? updated : l,
          ],
          page: current.page,
          limit: current.limit,
          total: current.total,
          pages: current.pages,
        ),
      );
    }
    return updated;
  }

  Future<void> deleteLocation(String id) async {
    await ref.read(locationRepositoryProvider).deleteLocation(id);

    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      LocationsPageState(
        locations: current.locations.where((l) => l.id != id).toList(),
        page: current.page,
        limit: current.limit,
        total: current.total - 1,
        pages: current.pages,
      ),
    );
  }
}

final locationControllerProvider =
    AsyncNotifierProvider<LocationController, LocationsPageState>(
  LocationController.new,
);
