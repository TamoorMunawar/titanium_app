import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../controllers/vehicle_controller.dart';
import '../core/network/api_exception.dart';
import '../models/vehicle.dart';
import '../widgets/add_location_sheet.dart';
import '../widgets/delete_vehicle_dialog.dart';
import '../widgets/mark_as_sold_dialog.dart';
import '../widgets/status_badge.dart';
import 'add_information_screen.dart';

String _orNotSet(String? value) =>
    (value == null || value.isEmpty) ? 'Not set' : value;

class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);
  static const _successGreen = Color(0xFF1B7A43);

  late Vehicle _vehicle = widget.vehicle;
  bool _isDeleting = false;
  bool _isMarkingSold = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final fresh = await ref
          .read(vehicleControllerProvider.notifier)
          .fetchVehicle(widget.vehicle.id);
      if (!mounted) return;
      setState(() {
        _vehicle = fresh;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      // Fall back to the cached vehicle passed in from the list so
      // navigation still works even if the refresh fails.
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh: ${e.message}')),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addLocation() async {
    final newLocation = await showAddLocationSheet(context, _vehicle);
    if (newLocation == null || newLocation.isEmpty || !mounted) return;

    try {
      final updated = await ref
          .read(vehicleControllerProvider.notifier)
          .updateVehicle(_vehicle.id, location: newLocation);
      if (!mounted) return;
      setState(() => _vehicle = updated);
      _showSuccessSnackBar('Location updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addInformation() async {
    // Fetch the latest data before editing, so the form isn't working off a
    // potentially stale cached copy.
    Vehicle latest;
    try {
      latest = await ref
          .read(vehicleControllerProvider.notifier)
          .fetchVehicle(_vehicle.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;

    final updated = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(builder: (_) => AddInformationScreen(vehicle: latest)),
    );
    if (updated == null || !mounted) return;

    setState(() => _vehicle = updated);
    _showSuccessSnackBar('Vehicle information updated');
  }

  Future<void> _markAsSold() async {
    final confirmed = await showMarkAsSoldDialog(context, _vehicle.name);
    if (!confirmed || !mounted) return;

    setState(() => _isMarkingSold = true);
    try {
      final updated = await ref
          .read(vehicleControllerProvider.notifier)
          .markAsSold(_vehicle.id);
      if (!mounted) return;
      setState(() {
        _vehicle = updated;
        _isMarkingSold = false;
      });
      _showSuccessSnackBar('Vehicle marked as sold');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingSold = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteVehicle() async {
    final confirmed = await showDeleteVehicleDialog(context, _vehicle.name);
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(vehicleControllerProvider.notifier)
          .deleteVehicle(_vehicle.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;
    final isGuest = ref.watch(authControllerProvider).user?.isGuest ?? false;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Vehicle Details',
                    style: TextStyle(
                      fontSize: 17,
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
                      Icons.ios_share_outlined,
                      color: Colors.black54,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isDeleting ? null : _deleteVehicle,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _fieldFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFDC2626),
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryCard(vehicle: vehicle, isGuest: isGuest),
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'VEHICLE INFORMATION',
                          rows: [
                            if (!isGuest) ('Chassis Number', vehicle.vin),
                            (
                              'Registration Number',
                              _orNotSet(vehicle.registrationNumber),
                            ),
                            ('Make', vehicle.make),
                            ('Model', vehicle.model),
                            ('Variant', vehicle.variant),
                            ('Manufacturing Year', vehicle.manufacturingYear),
                            ('Color', vehicle.color),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'LOCATION INFORMATION',
                          rows: [
                            ('Current Location', vehicle.currentLocation),
                            ('Last Updated', vehicle.lastUpdated),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _NotesCard(notes: vehicle.notes),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEBECF2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_vehicle.status == VehicleStatus.sold)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EAEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF6B7280)),
                      SizedBox(width: 6),
                      Text(
                        'Marked as Sold',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isMarkingSold ? null : _markAsSold,
                    icon: _isMarkingSold
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sell_outlined, size: 16),
                    label: const Text('Mark as Sold'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _addLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFE0E2E8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Location'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addInformation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add Information'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.vehicle, required this.isGuest});

  final Vehicle vehicle;

  /// Chassis numbers are sensitive stock data — hidden while browsing as a
  /// guest, since guests aren't tied to any Titanium Cars account.
  final bool isGuest;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
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
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_filled,
              color: _accentBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            vehicle.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          if (!isGuest) ...[
            const SizedBox(height: 4),
            Text(
              vehicle.vin,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
          const SizedBox(height: 10),
          StatusBadge(status: vehicle.status),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0FB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 13,
                  color: _accentBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  vehicle.currentLocation,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accentBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 17, color: Color(0xFFF0F1F5)),
            _InfoRow(label: rows[i].$1, value: rows[i].$2),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  static const _accentBlue = Color(0xFF2F5FDE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NOTES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: _accentBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            notes.isEmpty ? 'No notes added' : notes,
            style: TextStyle(
              fontSize: 13,
              color: notes.isEmpty ? Colors.black45 : Colors.black87,
              fontWeight: notes.isEmpty ? FontWeight.w400 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
