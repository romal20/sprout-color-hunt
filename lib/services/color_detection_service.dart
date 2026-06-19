import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/game_models.dart';

class ColorDetectionResult {
  final String colorName;
  final RainbowColor? rainbowColor;

  ColorDetectionResult({required this.colorName, this.rainbowColor});
}

class ColorDetectionService {
  /// Detect the dominant color in an image file.
  /// Returns a result with colorName and matching RainbowColor (if any).
  /// Never returns 'Unknown' — always falls back to the closest valid color.
  static ColorDetectionResult detectDominantColor(String imagePath) {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return ColorDetectionResult(colorName: 'Red', rainbowColor: RainbowColor.red);
      }

      final bytes = file.readAsBytesSync();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        return ColorDetectionResult(colorName: 'Red', rainbowColor: RainbowColor.red);
      }

      // Resize image for fast processing — 100×100 is plenty for color detection
      if (image.width > 100 || image.height > 100) {
        image = img.copyResize(image, width: 100, height: 100);
      }

      final Map<String, int> colorCounts = {};

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Skip nearly-transparent pixels if alpha exists
          final a = pixel.a.toInt();
          if (a < 30) continue;

          final colorName = _rgbToColorName(r, g, b);
          // Skip neutrals in first pass
          if (colorName == 'White' || colorName == 'Black' || colorName == 'Grey') {
            continue;
          }
          colorCounts[colorName] = (colorCounts[colorName] ?? 0) + 1;
        }
      }

      // If only neutrals found, do a second pass including them
      if (colorCounts.isEmpty) {
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();
            final colorName = _rgbToColorName(r, g, b);
            colorCounts[colorName] = (colorCounts[colorName] ?? 0) + 1;
          }
        }
      }

      if (colorCounts.isEmpty) {
        return ColorDetectionResult(colorName: 'Red', rainbowColor: RainbowColor.red);
      }

      // Find dominant color
      final sorted = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final dominantName = sorted.first.key;

      debugPrint('[ColorDetection] Top colors: ${sorted.take(3).map((e) => "${e.key}:${e.value}").join(", ")}');
      debugPrint('[ColorDetection] Dominant: $dominantName');

      return ColorDetectionResult(
        colorName: dominantName,
        rainbowColor: _toRainbowColor(dominantName),
      );
    } catch (e) {
      debugPrint('[ColorDetection] ERROR: $e');
      // Absolute fallback — never crash, never return Unknown
      return ColorDetectionResult(colorName: 'Red', rainbowColor: RainbowColor.red);
    }
  }

  static String _rgbToColorName(int r, int g, int b) {
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;

    final double maxC = math.max(rf, math.max(gf, bf));
    final double minC = math.min(rf, math.min(gf, bf));
    final double delta = maxC - minC;

    final double v = maxC;

    // Very dark → Black
    if (v < 0.12) return 'Black';

    // Very bright + low saturation → White
    if (v > 0.88 && delta < 0.08) return 'White';

    // Low saturation → Grey
    final double s = maxC > 0 ? delta / maxC : 0;
    if (s < 0.12) return 'Grey';

    // Compute hue
    double h = 0;
    if (delta > 0.001) {
      if (maxC == rf) {
        h = 60.0 * (((gf - bf) / delta) % 6);
      } else if (maxC == gf) {
        h = 60.0 * (((bf - rf) / delta) + 2);
      } else {
        h = 60.0 * (((rf - gf) / delta) + 4);
      }
      if (h < 0) h += 360.0;
    }

    // Only classify as a named color if saturation is meaningful
    // Use generous thresholds — children's objects are never perfectly saturated
    if (s >= 0.10 && v >= 0.10) {
      // Red — wraps around 360°, wider range
      if (h >= 340 || h < 20) return 'Red';
      // Orange
      if (h >= 20 && h < 45) return 'Orange';
      // Yellow — wide range because yellows vary a lot
      if (h >= 45 && h < 75) return 'Yellow';
      // Green
      if (h >= 75 && h < 168) return 'Green';
      // Blue/Cyan
      if (h >= 168 && h < 255) return 'Blue';
      // Purple/Violet
      if (h >= 255 && h < 310) return 'Purple';
      // Pink/Magenta
      if (h >= 310 && h < 340) return 'Pink';
    }

    // Brown detection — orange-ish hue but low value and low-medium saturation
    if (h >= 15 && h < 45 && s >= 0.15 && v >= 0.1 && v < 0.55) {
      return 'Brown';
    }

    // Fallback — classify by closest primary if we have any chromatic signal at all
    if (s >= 0.08) {
      // Just pick closest hue bucket
      if (h >= 340 || h < 30) return 'Red';
      if (h >= 30 && h < 75) return 'Yellow';
      if (h >= 75 && h < 168) return 'Green';
      if (h >= 168 && h < 255) return 'Blue';
      return 'Purple';
    }

    return 'Grey';
  }

  static RainbowColor? _toRainbowColor(String colorName) {
    switch (colorName) {
      case 'Red':
        return RainbowColor.red;
      case 'Blue':
        return RainbowColor.blue;
      case 'Green':
        return RainbowColor.green;
      case 'Yellow':
        return RainbowColor.yellow;
      case 'Purple':
        return RainbowColor.purple;
      // Map adjacent colors to game colors for better UX
      case 'Orange':
        return RainbowColor.red; // Orange objects count as Red
      case 'Pink':
        return RainbowColor.purple; // Pink counts as Purple
      default:
        return null;
    }
  }
}
