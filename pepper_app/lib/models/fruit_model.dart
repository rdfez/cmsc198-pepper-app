// Seed model
// Defines the data structure of the seed object
// Includes logic that determines which dimension to display in the UI
// * length and width = top-view detection

import 'dart:ui';

class FruitDetection {
  final int id;
  final String type;
  final Rect boundingBox;
  final double confidence; // Probability score
  
  double lengthMm = 0.0;
  double widthMm = 0.0;
  String? color;

  FruitDetection({
    required this.id,
    required this.type,
    required this.boundingBox,
    required this.confidence,
  });

  // Logic to determine which dimension to display based on data
  String get dimensionString {
    // top-view detection 
    if (lengthMm > 0 && widthMm > 0) {
      return "${lengthMm.toStringAsFixed(2)} x ${widthMm.toStringAsFixed(2)} mm";
    }
    // Fallback if no coin was found for calibration
    return "...";
  }
}