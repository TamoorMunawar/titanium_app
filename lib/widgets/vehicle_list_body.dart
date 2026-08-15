import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_detail_screen.dart';
import 'page_button.dart';
import 'status_badge.dart';

/// Search field + paginated vehicle list, backed by [provider]. Shared
/// between the User-side Vehicles screen, the Admin-side Inventory tab, and
/// the Sold Vehicles screen — all three browse/search `/v2/api/inventory`,
/// just scoped to a different status via which controller backs them.
class VehicleListBody extends ConsumerStatefulWidget {
  const VehicleListBody({
    super.key,
    required this.provider,
    this.listTitle = 'ALL VEHICLES',
  });

  final AsyncNotifierProvider<VehicleController, VehiclesPageState> provider;
  final String listTitle;

  @override
  ConsumerState<VehicleListBody> createState() => _VehicleListBodyState();
}

class _VehicleListBodyState extends ConsumerState<VehicleListBody> {
  static const _fieldFill = Color(0xFFF3F4F8);

  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _didInvalidate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // [provider] is a global, non-autoDispose provider, so revisiting a
    // pushed screen (e.g. Sold Vehicles) would otherwise just show
    // whatever it last fetched instead of picking up changes made
    // elsewhere in the meantime. Invalidating on mount forces a fresh
    // fetch every time this widget is (re)created. Can't do this in
    // initState — the ProviderScope isn't reachable until after it
    // completes — so it's guarded to run only once here instead.
    if (!_didInvalidate) {
      _didInvalidate = true;
      ref.invalidate(widget.provider);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(widget.provider.notifier).search(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(widget.provider);
    final isGuest = ref.watch(authControllerProvider).user?.isGuest ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            'Search chassis number or browse all vehicles',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by Car Chassis Number',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: Colors.black45,
              ),
              filled: true,
              fillColor: _fieldFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: vehiclesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: error.toString(),
              onRetry: () => ref.read(widget.provider.notifier).refresh(),
            ),
            data: (pageState) {
              final start = (pageState.page - 1) * pageState.limit;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      '${widget.listTitle} (${pageState.total})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: pageState.vehicles.isEmpty
                        ? const Center(
                            child: Text(
                              'No vehicles match your search',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black45,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            itemCount: pageState.vehicles.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _VehicleCard(
                              vehicle: pageState.vehicles[index],
                              isGuest: isGuest,
                            ),
                          ),
                  ),
                  if (pageState.total > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            '${start + 1}-${start + pageState.vehicles.length} of ${pageState.total}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 26,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (var i = 0; i < pageState.pages; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: PageButton(
                                        label: '${i + 1}',
                                        selected: i + 1 == pageState.page,
                                        onTap: () => ref
                                            .read(widget.provider.notifier)
                                            .goToPage(i + 1),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.black38, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.isGuest});

  final Vehicle vehicle;

  /// Chassis numbers are sensitive stock data — hidden while browsing as a
  /// guest, since guests aren't tied to any Titanium Cars account.
  final bool isGuest;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_car_filled,
                  color: _accentBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (!isGuest) ...[
                      const SizedBox(height: 2),
                      Text(
                        vehicle.vin,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(status: vehicle.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Updated ${vehicle.lastUpdated}',
            style: const TextStyle(fontSize: 11, color: Colors.black38),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _ViewDetailsButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.onPressed});

  final VoidCallback onPressed;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.visibility_outlined, size: 16),
      label: const Text('View Details'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
