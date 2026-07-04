import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

// ---------------------------------------------------------------------------
// CONFIG — adjust these to match your training / export setup
// ---------------------------------------------------------------------------

/// Must match the `imgsz` used when you exported the ONNX model.
const int kInputSize = 640;

/// Minimum detection confidence to keep.
const double kConfThreshold = 0.1;

/// The real-world length (in cm) that the RULER's detected bounding-box
/// WIDTH represents. Set this to match your actual capture setup — e.g.
/// if the ruler is always framed so its box spans 24 cm, use 24.0.
/// If your capture distance/zoom varies, this assumption breaks down —
/// switch to tick-mark detection instead.
const double kRulerLengthCm = 24.0;

/// Class names in the EXACT order used in your data.yaml, including the
/// ruler class. Update the ruler's position/name to match your dataset.
const List<String> kClassNames = [
  'coin', 
  'fruit_shape_blocky', 
  'fruit_shape_conical', 
  'fruit_shape_elongate', 
  'fruit_shape_horn', 
  'fruit_shape_oblate', 
  'fruit_shape_round', 
  'ruler'
];

final int kRulerClassIndex = kClassNames.indexOf('ruler');

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

class Detection {
  final int classId;
  final double confidence;
  final double x1, y1, x2, y2; // pixel coords in the ORIGINAL (unresized) image

  Detection({
    required this.classId,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  double get widthPx => x2 - x1;
  double get heightPx => y2 - y1;
  String get label => kClassNames[classId];
  double get areaPx => widthPx * heightPx;   // ← new
}

// ← new: IoU helper
double _iou(Detection a, Detection b) {
  final interX1 = math.max(a.x1, b.x1);
  final interY1 = math.max(a.y1, b.y1);
  final interX2 = math.min(a.x2, b.x2);
  final interY2 = math.min(a.y2, b.y2);
  final interW = math.max(0, interX2 - interX1);
  final interH = math.max(0, interY2 - interY1);
  final interArea = interW * interH;
  if (interArea <= 0) return 0;
  final unionArea = a.areaPx + b.areaPx - interArea;
  return unionArea <= 0 ? 0 : interArea / unionArea;
}

// ← new: greedy class-agnostic NMS
List<Detection> _suppressOverlaps(
  List<Detection> detections, {
  double iouThreshold = 0.45,
}) {
  final sorted = [...detections]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));
  final kept = <Detection>[];
  for (final candidate in sorted) {
    final overlapsKept =
        kept.any((k) => _iou(candidate, k) > iouThreshold);
    if (!overlapsKept) kept.add(candidate);
  }
  return kept;
}

class FruitMeasurement {
  final String shape;
  final double confidence;
  final double? lengthCm;
  final double? widthCm;

  final double xFrac1, yFrac1, xFrac2, yFrac2;

  FruitMeasurement({
    required this.shape,
    required this.confidence,
    this.lengthCm,
    this.widthCm,
    required this.xFrac1,
    required this.yFrac1,
    required this.xFrac2,
    required this.yFrac2,
  });

  @override
  String toString() {
    final size = (lengthCm != null && widthCm != null)
        ? '${lengthCm!.toStringAsFixed(1)} cm (L) x ${widthCm!.toStringAsFixed(1)} cm (W)'
        : 'size unavailable (no ruler)';
    return '$shape (conf ${confidence.toStringAsFixed(2)}): $size';
  }
}

/// Bundles the per-fruit measurements together with the original image's
/// pixel dimensions, so downstream UI can correctly scale/overlay boxes.
class AnalysisResult {
  final List<FruitMeasurement> fruits;
  final int imageWidth;
  final int imageHeight;
  final bool hasRuler;

  AnalysisResult({
    required this.fruits,
    required this.imageWidth,
    required this.imageHeight,
    required this.hasRuler,
  });
}

// ---------------------------------------------------------------------------
// ANALYZER
// ---------------------------------------------------------------------------

class PepperAnalyzer {
  OrtSession? _session;

  /// Load the ONNX model from a local file path (e.g. after copying it out
  /// of assets into a temp/app-documents directory, as onnxruntime typically
  /// needs a real file path or byte buffer).
  Future<void> loadModel(Uint8List modelBytes) async {
    OrtEnv.instance.init();
  final sessionOptions = OrtSessionOptions();
  _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
  }

  /// Runs inference on [imageFile] and returns fruit measurements,
  /// bundled with the original image's pixel dimensions. Always returns a
  /// result — if no ruler was found, `hasRuler` is false and every
  /// fruit's `lengthCm`/`widthCm` will be null (shape + box are still valid).
  Future<AnalysisResult> analyze(File imageFile) async {
    if (_session == null) {
      throw StateError('Call loadModel() before analyze().');
    }

    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) throw Exception('Could not decode image.');

    final origW = original.width;
    final origH = original.height;

    // --- Letterbox resize to kInputSize x kInputSize (preserve aspect ratio)
    final scale = math.min(kInputSize / origW, kInputSize / origH);
    final newW = (origW * scale).round();
    final newH = (origH * scale).round();
    final resized = img.copyResize(original, width: newW, height: newH);

    final padded = img.Image(width: kInputSize, height: kInputSize);
    img.fill(padded, color: img.ColorRgb8(114, 114, 114));
    final padX = (kInputSize - newW) ~/ 2;
    final padY = (kInputSize - newH) ~/ 2;
    img.compositeImage(padded, resized, dstX: padX, dstY: padY);

    // --- Build NCHW float32 tensor, normalized to 0-1
    final inputData = Float32List(1 * 3 * kInputSize * kInputSize);
    int idx = 0;
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < kInputSize; y++) {
        for (int x = 0; x < kInputSize; x++) {
          final pixel = padded.getPixel(x, y);
          final value = c == 0 ? pixel.r : (c == 1 ? pixel.g : pixel.b);
          inputData[idx++] = value / 255.0;
        }
      }
    }

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputData,
      [1, 3, kInputSize, kInputSize],
    );
    final runOptions = OrtRunOptions();

    // NOTE: input name 'images' is the Ultralytics default export input
    // name — confirm with a quick `session.inputNames` print if unsure.
    final outputs = await _session!.runAsync(runOptions, {'images': inputOrt});
    inputOrt.release();
    runOptions.release();

    // NOTE: because you exported with nms=True, output is typically shaped
    // [num_detections, 6] = [x1, y1, x2, y2, score, class] in the 640x640
    // letterboxed coordinate space. PRINT the raw output shape once on your
    // actual model to confirm before trusting this parsing as-is.
    final rawOutput =
    (outputs?[0]?.value as List<List<List<double>>>).first;

    final detections = <Detection>[];
    for (final row in rawOutput) {
      final score = row[4];
      if (score < kConfThreshold) continue;
      final classId = row[5].round();

      // ignore: avoid_print
      print('RAW row: class=$classId conf=${score.toStringAsFixed(3)}');
 
      if (score < kConfThreshold) continue;

      // Undo letterbox padding + scale -> back to original image pixels.
      final x1 = (row[0] - padX) / scale;
      final y1 = (row[1] - padY) / scale;
      final x2 = (row[2] - padX) / scale;
      final y2 = (row[3] - padY) / scale;

      detections.add(Detection(
        classId: classId,
        confidence: score,
        x1: x1.clamp(0, origW.toDouble()),
        y1: y1.clamp(0, origH.toDouble()),
        x2: x2.clamp(0, origW.toDouble()),
        y2: y2.clamp(0, origH.toDouble()),
      ));
    }

    for (final o in outputs ?? <OrtValue?>[]) {
      o?.release();
    }

    // --- DEBUG: log every detection the model found, before any filtering.
    // Remove or comment out once ruler detection is working reliably.
    // ignore: avoid_print
    print('--- All detections (${detections.length}) ---');
    for (final d in detections) {
      // ignore: avoid_print
      print('class=${d.classId} (${kClassNames[d.classId]}) '
          'conf=${d.confidence.toStringAsFixed(3)} '
          'box=[${d.x1.toStringAsFixed(0)},${d.y1.toStringAsFixed(0)},'
          '${d.x2.toStringAsFixed(0)},${d.y2.toStringAsFixed(0)}]');
    }

    final deduped = _suppressOverlaps(detections);

    // --- Calibrate scale from the ruler detection
    final rulerDet = deduped          // ← was: detections
        .where((d) => d.classId == kRulerClassIndex)
        .fold<Detection?>(
      null,
      (best, d) => (best == null || d.confidence > best.confidence) ? d : best,
    );

    if (rulerDet == null) {
      // ignore: avoid_print
      print('No ruler detected — proceeding without size calibration.');
    }

    final double? pixelsPerCm =
        rulerDet == null ? null : rulerDet.widthPx / kRulerLengthCm;

    final results = <FruitMeasurement>[];
    for (final d in deduped) {
      if (d.classId == kRulerClassIndex) continue;
      results.add(FruitMeasurement(
        shape: d.label,
        confidence: d.confidence,
        lengthCm: pixelsPerCm == null ? null : d.heightPx / pixelsPerCm,
        widthCm: pixelsPerCm == null ? null : d.widthPx / pixelsPerCm,
        xFrac1: d.x1 / origW,
        yFrac1: d.y1 / origH,
        xFrac2: d.x2 / origW,
        yFrac2: d.y2 / origH,
      ));
    }
    return AnalysisResult(
      fruits: results,
      imageWidth: origW,
      imageHeight: origH,
      hasRuler: rulerDet != null,
    );
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}

// ---------------------------------------------------------------------------
// EXAMPLE USAGE
// ---------------------------------------------------------------------------
//
// final analyzer = PepperAnalyzer();
// await analyzer.loadModel('/path/to/best.onnx');
// final results = await analyzer.analyze(File('/path/to/photo.jpg'));
// if (results == null) {
//   print('No ruler detected — cannot calibrate size for this image.');
// } else {
//   for (final r in results) {
//     print(r); // e.g. "conical (conf 0.94): 4.2 cm (L) x 2.8 cm (W)"
//   }
// }
// analyzer.dispose();