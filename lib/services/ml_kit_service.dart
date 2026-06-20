import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlKitService {
  static final MlKitService _instance = MlKitService._internal();
  factory MlKitService() => _instance;
  MlKitService._internal();

  /// Label an image by file path. Returns best human-readable label.
  /// Never returns empty string. Falls back to 'Object' on any failure.
  /// 5-second timeout prevents endless loading.
  Future<String> labelImage(String imagePath) async {
    if (kIsWeb) {
      debugPrint('[MlKit] Skipping on web — returning "Object"');
      return 'Object';
    }

    ImageLabeler? labeler;
    try {
      debugPrint('[MlKit] Processing: $imagePath');

      labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.0),
      );

      final inputImage = InputImage.fromFilePath(imagePath);

      // 5-second timeout — prevents endless loading if ML Kit hangs
      final labels = await labeler
          .processImage(inputImage)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('[MlKit] Timeout — returning empty list');
        return [];
      });

      debugPrint('[MlKit] Labels returned: ${labels.length}');
      for (final l in labels) {
        debugPrint(
            '[MlKit]   "${l.label}" — ${(l.confidence * 100).toStringAsFixed(1)}%');
      }

      if (labels.isEmpty) return 'Object';

      // Sort by confidence descending — always use highest confidence first
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      // Walk from highest confidence, pick first non-generic label
      for (final label in labels) {
        final cleaned = _cleanLabel(label.label);
        if (cleaned.isNotEmpty && !_isGenericLabel(cleaned)) {
          debugPrint(
              '[MlKit] Best label: "$cleaned" (${(label.confidence * 100).toStringAsFixed(1)}%)');
          return cleaned;
        }
      }

      // All labels are generic — return the top one rather than "Object"
      // so real things like "Apple", "Bottle" still appear
      final top = _cleanLabel(labels.first.label);
      debugPrint('[MlKit] All generic, using top: "$top"');
      return top.isNotEmpty ? top : 'Object';
    } catch (e, st) {
      debugPrint('[MlKit] ERROR: $e\n$st');
      return 'Object';
    } finally {
      try {
        await labeler?.close();
      } catch (_) {}
    }
  }

  String _cleanLabel(String label) {
    if (label.isEmpty) return '';
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}'
            : w)
        .join(' ')
        .trim();
  }

  bool _isGenericLabel(String label) {
    // Only truly unhelpful meta-labels — NOT object names.
    // Apple, Bottle, Book, Fruit, etc. are intentionally NOT in this list.
    const generic = <String>{
      'Organism',
      'Still life photography',
      'Macro photography',
      'Photography',
      'Stock photography',
      'Creative arts',
      'Font',
      'Unknown',
      'None',
      'Entity',
      'Texture',
      'Pattern',
      'Background',
      'Scene',
    };
    return generic.contains(label);
  }

  void dispose() {}
}
