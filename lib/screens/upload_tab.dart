import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/inventory_import_result.dart';
import '../widgets/app_top_bar.dart';
import 'upload_confirm_screen.dart';

class UploadTab extends StatefulWidget {
  const UploadTab({super.key, required this.onViewInventory});

  final VoidCallback onViewInventory;

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  static const _accentBlue = Color(0xFF2F5FDE);
  static const _allowedExtensions = ['xlsx', 'xls', 'csv', 'pdf'];

  bool _showSuccess = false;
  InventoryImportResult? _importResult;

  Future<void> _pickAndImport() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.single;
    if (file.path == null || !mounted) return;

    // Some Android file managers ignore `allowedExtensions` for
    // FileType.custom and let the user pick any file, so re-check here.
    final extension = file.extension?.toLowerCase();
    if (extension == null || !_allowedExtensions.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a .xlsx, .xls, .csv, or .pdf file'),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<InventoryImportResult>(
      MaterialPageRoute(
        builder: (_) => UploadConfirmScreen(
          filePath: file.path!,
          fileName: file.name,
          fileSizeBytes: file.size,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _importResult = result;
      _showSuccess = true;
    });
  }

  void _viewInventory() {
    setState(() {
      _showSuccess = false;
      _importResult = null;
    });
    widget.onViewInventory();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopBar(title: 'Upload Inventory'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _showSuccess ? _buildSuccessCard() : _buildDropZone(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    final result = _importResult!;
    final subtitleBuffer = StringBuffer(
      '${result.totalRows} rows processed — ${result.inserted} inserted, '
      '${result.updated} updated.',
    );
    if (result.failed.isNotEmpty) {
      subtitleBuffer.write(' ${result.failed.length} row(s) failed.');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBECF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: result.failed.isEmpty
                  ? const Color(0xFFE6F7ED)
                  : const Color(0xFFFFF4E5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              result.failed.isEmpty ? Icons.check_rounded : Icons.warning_amber_rounded,
              color: result.failed.isEmpty
                  ? const Color(0xFF1FA76A)
                  : const Color(0xFFD97706),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Import Successful',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitleBuffer.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _viewInventory,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View Inventory'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickAndImport,
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: Color(0xFFD7DAE3),
          radius: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.upload_rounded,
                  color: _accentBlue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Drag & drop your file here',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'or tap to browse your files',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _FileTypeChip(label: '.XLSX'),
                  _FileTypeChip(label: '.XLS'),
                  _FileTypeChip(label: '.CSV'),
                  _FileTypeChip(label: '.PDF'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileTypeChip extends StatelessWidget {
  const _FileTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E2E8)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const _dashWidth = 6.0;
  static const _gapWidth = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapWidth;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}
