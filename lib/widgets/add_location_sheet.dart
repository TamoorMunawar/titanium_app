import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/location_controller.dart';
import '../models/vehicle.dart';

Future<String?> showAddLocationSheet(BuildContext context, Vehicle vehicle) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddLocationSheet(vehicle: vehicle),
  );
}

class AddLocationSheet extends ConsumerStatefulWidget {
  const AddLocationSheet({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends ConsumerState<AddLocationSheet> {
  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);

  late final TextEditingController _locationController;
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedExisting;
  List<String>? _existingLocationNames;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: widget.vehicle.currentLocation,
    );
    _loadLocationOptions();
  }

  Future<void> _loadLocationOptions() async {
    try {
      // A generous limit so this picks up effectively all locations in one
      // call, independent of whatever page the Locations tab happens to be
      // showing.
      final result = await ref
          .read(locationRepositoryProvider)
          .listLocations(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _existingLocationNames = [for (final l in result.locations) l.name];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _existingLocationNames = const []);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _saveLocation() {
    Navigator.of(context).pop(_locationController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingLocations = _existingLocationNames == null;
    final locationNames = _existingLocationNames ?? const <String>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'Add Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Existing Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedExisting,
                    isExpanded: true,
                    hint: Text(
                      isLoadingLocations
                          ? 'Loading locations...'
                          : locationNames.isEmpty
                              ? 'No saved locations yet'
                              : 'Select a location',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    items: [
                      for (final name in locationNames)
                        DropdownMenuItem(value: name, child: Text(name)),
                    ],
                    onChanged: locationNames.isEmpty
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedExisting = value;
                              _locationController.text = value;
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'or type a new location below',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
              const SizedBox(height: 12),
              const Text(
                'Location Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationController,
                decoration: _decoration('Warehouse A'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Landmark (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _landmarkController,
                decoration: _decoration('e.g. Near main gate'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Additional Notes (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                minLines: 3,
                maxLines: 4,
                decoration: _decoration('Any extra details...'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveLocation,
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
                      child: const Text('Save Location'),
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
