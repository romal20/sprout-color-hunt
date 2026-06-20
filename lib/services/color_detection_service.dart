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
  // ── Web-safe entry point ──────────────────────────────────────────────────
  /// Use this on Flutter Web — accepts raw bytes (XFile.readAsBytes()).
  static ColorDetectionResult detectDominantColorFromBytes(Uint8List bytes) {
    try {
      debugPrint('[ColorDetection] fromBytes: ${bytes.length} bytes');
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('[ColorDetection] decodeImage returned null');
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      }
      return _analyzeImage(image);
    } catch (e) {
      debugPrint('[ColorDetection] fromBytes ERROR: $e');
      return ColorDetectionResult(
          colorName: 'Red', rainbowColor: RainbowColor.red);
    }
  }

  // ── Native (Android/iOS) entry point ─────────────────────────────────────
  /// Reads from filesystem. Do NOT call on web.
  static ColorDetectionResult detectDominantColor(String imagePath) {
    try {
      debugPrint('[ColorDetection] detectDominantColor: $imagePath');
      final file = File(imagePath);
      if (!file.existsSync()) {
        debugPrint('[ColorDetection] File not found: $imagePath');
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      }
      final bytes = file.readAsBytesSync();
      debugPrint('[ColorDetection] Read ${bytes.length} bytes');
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('[ColorDetection] decodeImage returned null');
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      }
      return _analyzeImage(image);
    } catch (e) {
      debugPrint('[ColorDetection] detectDominantColor ERROR: $e');
      return ColorDetectionResult(
          colorName: 'Red', rainbowColor: RainbowColor.red);
    }
  }

  // ── Shared pixel-analysis core ────────────────────────────────────────────
  static ColorDetectionResult _analyzeImage(img.Image raw) {
    try {
      // Resize for fast processing
      final image = (raw.width > 100 || raw.height > 100)
          ? img.copyResize(raw, width: 100, height: 100)
          : raw;

      final Map<String, int> colorCounts = {};

      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final a = pixel.a.toInt();
          if (a < 30) continue;
          final colorName = _rgbToColorName(r, g, b);
          if (colorName == 'White' ||
              colorName == 'Black' ||
              colorName == 'Grey') continue;
          colorCounts[colorName] = (colorCounts[colorName] ?? 0) + 1;
        }
      }

      // Second pass including neutrals if nothing found
      if (colorCounts.isEmpty) {
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final colorName = _rgbToColorName(
                pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
            colorCounts[colorName] = (colorCounts[colorName] ?? 0) + 1;
          }
        }
      }

      if (colorCounts.isEmpty) {
        return ColorDetectionResult(
            colorName: 'Red', rainbowColor: RainbowColor.red);
      }

      final sorted = colorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final dominantName = sorted.first.key;

      debugPrint(
          '[ColorDetection] Top: ${sorted.take(3).map((e) => "${e.key}:${e.value}").join(", ")}');
      debugPrint('[ColorDetection] Dominant: $dominantName');

      return ColorDetectionResult(
        colorName: dominantName,
        rainbowColor: _toRainbowColor(dominantName),
      );
    } catch (e) {
      debugPrint('[ColorDetection] _analyzeImage ERROR: $e');
      return ColorDetectionResult(
          colorName: 'Red', rainbowColor: RainbowColor.red);
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

    if (v < 0.12) return 'Black';
    // Tighter White gate: require very low delta AND very high brightness.
    // This prevents bright yellows (banana, paper) being misclassified as White.
    if (v > 0.92 && delta < 0.06) return 'White';

    final double s = maxC > 0 ? delta / maxC : 0;
    if (s < 0.10) return 'Grey';

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

    if (s >= 0.10 && v >= 0.10) {
      if (h >= 340 || h < 20) return 'Red';
      if (h >= 20 && h < 42) return 'Orange';
      // Yellow: wider range (42–82°) catches warm yellows, banana yellows,
      // greenish-yellows and paper yellows that previously fell into Orange/Green
      if (h >= 42 && h < 82) return 'Yellow';
      if (h >= 82 && h < 168) return 'Green';
      if (h >= 168 && h < 255) return 'Blue';
      if (h >= 255 && h < 310) return 'Purple';
      if (h >= 310 && h < 340) return 'Pink';
    }

    if (h >= 15 && h < 42 && s >= 0.15 && v >= 0.1 && v < 0.55) return 'Brown';

    // Low-saturation fallback — use lower threshold (0.06) so pale/faded
    // yellow objects still register instead of falling through to Grey
    if (s >= 0.06) {
      if (h >= 340 || h < 25) return 'Red';
      if (h >= 25 && h < 42) return 'Orange';
      if (h >= 42 && h < 82) return 'Yellow';
      if (h >= 82 && h < 168) return 'Green';
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
      case 'Orange':
        return RainbowColor.red; // orange → red
      case 'Pink':
        return RainbowColor.purple; // pink → purple
      default:
        return null;
    }
  }
}
