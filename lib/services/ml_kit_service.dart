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

      // Collect all non-generic labels
      final candidates = <String>[];
      for (final label in labels) {
        final cleaned = _cleanLabel(label.label);
        if (cleaned.isNotEmpty && !_isGenericLabel(cleaned)) {
          candidates.add(cleaned);
        }
      }

      if (candidates.isNotEmpty) {
        // Prefer the most specific (shortest word-count) among the top
        // candidates — "Apple" beats "Fresh fruit", "Bottle" beats "Glass container"
        candidates.sort((a, b) {
          final wa = a.split(' ').length;
          final wb = b.split(' ').length;
          if (wa != wb) return wa.compareTo(wb); // fewer words = more specific
          return a.compareTo(b); // alphabetical tiebreak
        });
        final best = candidates.first;
        debugPrint('[MlKit] Best label: "$best"');
        return best;
      }

      // All labels are generic — return the highest-confidence one anyway
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
    // Truly unhelpful labels that add no information to the user.
    // Concrete object names (Apple, Bottle, Book, Fruit, Flower, Cup…)
    // must NOT be in this list — they should always be shown.
    const generic = <String>{
      // Meta / photography terms
      'Organism',
      'Still life photography',
      'Macro photography',
      'Photography',
      'Stock photography',
      'Creative arts',
      'Font',
      // Completely uninformative
      'Unknown',
      'None',
      'Object',
      'Item',
      'Thing',
      'Entity',
      'Texture',
      'Pattern',
      'Background',
      'Scene',
      'Image',
      'Photo',
      'Picture',
      'Color',
      'Colour',
      'Shape',
      'Product',
      'Display',
      'Symbol',
    };
    return generic.contains(label);
  }

  void dispose() {}
}
