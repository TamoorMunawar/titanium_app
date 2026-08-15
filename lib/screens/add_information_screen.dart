import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/vehicle_controller.dart';
import '../core/network/api_exception.dart';
import '../models/vehicle.dart';
import '../widgets/save_changes_dialog.dart';

class AddInformationScreen extends ConsumerStatefulWidget {
  const AddInformationScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<AddInformationScreen> createState() =>
      _AddInformationScreenState();
}

class _AddInformationScreenState extends ConsumerState<AddInformationScreen> {
  static const _accentBlue = Color(0xFF2F5FDE);
  static const _fieldFill = Color(0xFFF3F4F8);

  late final _chassisNumberController = TextEditingController(
    text: widget.vehicle.vin,
  );
  late final _registrationNumberController = TextEditingController(
    text: widget.vehicle.registrationNumber ?? '',
  );
  late final _makeController = TextEditingController(text: widget.vehicle.make);
  late final _modelController = TextEditingController(
    text: widget.vehicle.model,
  );
  late final _variantController = TextEditingController(
    text: widget.vehicle.variant,
  );
  late final _manufacturingYearController = TextEditingController(
    text: widget.vehicle.manufacturingYear,
  );
  late final _colorController = TextEditingController(
    text: widget.vehicle.color,
  );

  late final _notesController = TextEditingController(
    text: widget.vehicle.notes,
  );

  @override
  void dispose() {
    _chassisNumberController.dispose();
    _registrationNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _manufacturingYearController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _saveChanges() async {
    final confirmed = await showSaveChangesDialog(context);
    if (!confirmed || !mounted) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Only `color` is a confirmed-editable field on the real inventory API
    // (via `PUT /v2/api/inventory/:id`); everything else here stays a
    // local-only annotation on top of that, same as before.
    Vehicle base = widget.vehicle;
    final newColor = _colorController.text.trim();
    if (newColor != widget.vehicle.color) {
      try {
        base = await ref
            .read(vehicleControllerProvider.notifier)
            .updateVehicle(widget.vehicle.id, color: newColor);
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _isSaving = false;
          _errorMessage = e.message;
        });
        return;
      }
    }
    if (!mounted) return;

    final updated = base.copyWith(
      registrationNumber: _registrationNumberController.text.trim(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      variant: _variantController.text.trim(),
      manufacturingYear: _manufacturingYearController.text.trim(),
      color: newColor,
      notes: _notesController.text.trim(),
      lastUpdated: 'Just now',
      updatedBy: 'You',
    );

    Navigator.of(context).pop(updated);
  }

  InputDecoration _decoration() {
    return InputDecoration(
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(controller: controller, decoration: _decoration()),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: _accentBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Add Information',
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
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEAEA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _sectionTitle('VEHICLE DETAILS'),
                      _field('Chassis Number', _chassisNumberController),
                      _field(
                        'Registration Number',
                        _registrationNumberController,
                      ),
                      _field('Make', _makeController),
                      _field('Model', _modelController),
                      _field('Variant', _variantController),
                      _field(
                        'Manufacturing Year',
                        _manufacturingYearController,
                      ),
                      _field('Color', _colorController),
                      _sectionTitle('ADDITIONAL NOTES'),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notes',
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
                            decoration: _decoration(),
                          ),
                        ],
                      ),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
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
                  onPressed: _isSaving ? null : _saveChanges,
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
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
