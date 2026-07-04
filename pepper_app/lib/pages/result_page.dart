import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pepper_app/utils/analyzer.dart';

// Get cleaned label
String _getShapeLabel(String raw) {
  final cleaned = raw
      .replaceAll(
        RegExp(r'fruit[\s_-]*shape[\s_:-]*', caseSensitive: false),
        '',
      )
      .trim();
  final words = cleaned.split(RegExp(r'[_\s-]+')).where((w) => w.isNotEmpty);
  return words
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

// Analysis Results Page
class AnalysisResultsPage extends StatelessWidget {
  final File imageFile;
  final AnalysisResult result;

  const AnalysisResultsPage({
    super.key,
    required this.imageFile,
    required this.result,
  });

  Future<void> _exportCsv(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('Index,Shape,Length_cm,Width_cm,Confidence');
    for (var i = 0; i < result.fruits.length; i++) {
      final f = result.fruits[i];
      buffer.writeln(
        '${i + 1},${_getShapeLabel(f.shape)},'
        '${f.lengthCm?.toStringAsFixed(2) ?? ''},'
        '${f.widthCm?.toStringAsFixed(2) ?? ''},'
        '${f.confidence.toStringAsFixed(3)}',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pepper_measurements.csv');
    await file.writeAsString(buffer.toString());

    // Open the share overlay so the user can save/export results
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Pepper shape & size measurements',
    );
  }

  String _formatSize(FruitMeasurement f) {
    if (f.lengthCm == null || f.widthCm == null) return '—';
    return '${f.lengthCm!.toStringAsFixed(1)} x ${f.widthCm!.toStringAsFixed(1)}';
  }

  Widget _buildNoRulerBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No ruler detected — sizes are unavailable for this photo.',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!result.hasRuler) _buildNoRulerBanner(),
              _buildLabeledImage(),
              const SizedBox(height: 20),
              _buildCountAndExport(context),
              const SizedBox(height: 20),
              Expanded(child: _buildResultsTable()),
            ],
          ),
        ),
      ),
    );
  }

  // Labeled image with bounding boxes and shape labels
  Widget _buildLabeledImage() {
    final aspectRatio = result.imageWidth / result.imageHeight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        // Forces box to match the original photo's aspect ratio
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(imageFile, fit: BoxFit.fill),
            CustomPaint(
              painter: _DetectionBoxPainter(result.fruits),
            ),
          ],
        ),
      ),
    );
  }

  // Total Count and Export CSV button
  Widget _buildCountAndExport(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Total Count
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.fruits.length}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text('peppers detected'),
          ],
        ),

        // Export CSV button
        FilledButton.icon(
          onPressed: result.fruits.isEmpty
              ? null
              : () => _exportCsv(context),
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
        ),
      ],
    );
  }

  // Actual Results (Tabular)
  Widget _buildResultsTable() {
    // No fruits detected
    if (result.fruits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No peppers detected in this photo.')),
      );
    }
    // Fruits detected, show table results
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('L x W (cm)')),
            DataColumn(label: Text('Conf.')),
          ],
          rows: [
            for (var i = 0; i < result.fruits.length; i++)
              DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(_getShapeLabel(result.fruits[i].shape))),
                DataCell(Text(_formatSize(result.fruits[i]))),
                DataCell(Text(
                  '${(result.fruits[i].confidence * 100).toStringAsFixed(0)}%',
                )),
              ]),
          ],
        ),
      )
    );
  }
}

// Draw each fruit's bounding box with shape labels 
class _DetectionBoxPainter extends CustomPainter {
  final List<FruitMeasurement> fruits;

  _DetectionBoxPainter(this.fruits);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < fruits.length; i++) {
      final f = fruits[i];
      final rect = Rect.fromLTRB(
        f.xFrac1 * size.width,
        f.yFrac1 * size.height,
        f.xFrac2 * size.width,
        f.yFrac2 * size.height,
      );
      canvas.drawRect(rect, boxPaint);

      final label = _getShapeLabel(f.shape);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelBgRect = Rect.fromLTWH(
        rect.left,
        (rect.top - textPainter.height - 2).clamp(0, size.height),
        textPainter.width + 8,
        textPainter.height + 2,
      );
      canvas.drawRect(
        labelBgRect,
        Paint()..color = Colors.green.withOpacity(0.85),
      );
      textPainter.paint(canvas, Offset(labelBgRect.left + 4, labelBgRect.top));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionBoxPainter oldDelegate) =>
      oldDelegate.fruits != fruits;
}