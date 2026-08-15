import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/location_controller.dart';
import '../core/network/api_exception.dart';
import '../models/location_record.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/create_location_sheet.dart';
import '../widgets/delete_location_dialog.dart';
import '../widgets/edit_location_sheet.dart';
import '../widgets/icon_action_button.dart';
import '../widgets/page_button.dart';

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class LocationsTab extends ConsumerStatefulWidget {
  const LocationsTab({super.key});

  @override
  ConsumerState<LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends ConsumerState<LocationsTab> {
  static const _accentBlue = Color(0xFF2F5FDE);

  Future<void> _addLocation() async {
    await showCreateLocationSheet(context);
  }

  Future<void> _editLocation(LocationRecord location) async {
    final newName = await showEditLocationSheet(context, location.name);
    if (newName == null || newName.isEmpty || !mounted) return;

    try {
      await ref
          .read(locationControllerProvider.notifier)
          .updateLocation(location.id, newName);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _confirmDelete(LocationRecord location) async {
    final confirmed = await showDeleteLocationDialog(context, location.name);
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(locationControllerProvider.notifier)
          .deleteLocation(location.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationControllerProvider);

    return Stack(
      children: [
        Column(
          children: [
            const AppTopBar(title: 'Locations'),
            Expanded(
              child: locationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(locationControllerProvider.notifier).refresh(),
                ),
                data: (pageState) {
                  final start = (pageState.page - 1) * pageState.limit;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pageState.total} locations across your network',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (pageState.locations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No locations yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          )
                        else
                          for (var i = 0; i < pageState.locations.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _LocationCard(
                              location: pageState.locations[i],
                              onEdit: () => _editLocation(pageState.locations[i]),
                              onDelete: () =>
                                  _confirmDelete(pageState.locations[i]),
                            ),
                          ],
                        if (pageState.total > 0) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${start + 1}-${start + pageState.locations.length} of ${pageState.total}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              const Spacer(),
                              for (var i = 0; i < pageState.pages; i++)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: PageButton(
                                    label: '${i + 1}',
                                    selected: i + 1 == pageState.page,
                                    onTap: () => ref
                                        .read(locationControllerProvider.notifier)
                                        .goToPage(i + 1),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: _accentBlue,
            onPressed: _addLocation,
            child: const Icon(Icons.add, color: Colors.white),
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.onEdit,
    required this.onDelete,
  });

  final LocationRecord location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
      child: Row(
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
              Icons.location_on_rounded,
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
                  location.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Created ${_formatDate(location.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconActionButton(icon: Icons.edit_outlined, onTap: onEdit),
                    const SizedBox(width: 4),
                    IconActionButton(icon: Icons.delete_outline, onTap: onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
