import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlKitService {
  static final MlKitService _instance = MlKitService._internal();
  factory MlKitService() => _instance;
  MlKitService._internal();

  // Do NOT cache the labeler across calls — re-create it each time to avoid
  // stale-state issues that cause silent empty results.
  Future<String> labelImage(String imagePath) async {
    ImageLabeler? labeler;
    try {
      debugPrint('[MlKit] Processing: $imagePath');

      labeler = ImageLabeler(
        options: ImageLabelerOptions(
          // 0.0 threshold = return ALL labels; we pick the best ourselves
          confidenceThreshold: 0.0,
        ),
      );

      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await labeler.processImage(inputImage);

      debugPrint('[MlKit] Labels returned: ${labels.length}');
      for (final l in labels) {
        debugPrint('[MlKit]   "${l.label}" — ${(l.confidence * 100).toStringAsFixed(1)}%');
      }

      if (labels.isEmpty) {
        debugPrint('[MlKit] No labels found, returning "Object"');
        return 'Object';
      }

      // Sort by confidence descending
      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      // Walk the list looking for the first non-generic label
      for (final label in labels) {
        final cleaned = _cleanLabel(label.label);
        if (!_isGenericLabel(cleaned)) {
          debugPrint('[MlKit] Best label: "$cleaned" (${(label.confidence * 100).toStringAsFixed(1)}%)');
          return cleaned;
        }
      }

      // All labels are generic — return the top one anyway so we show something
      final top = _cleanLabel(labels.first.label);
      debugPrint('[MlKit] All generic, using top: "$top"');
      return top.isEmpty ? 'Object' : top;
    } catch (e, st) {
      debugPrint('[MlKit] ERROR: $e');
      debugPrint('[MlKit] $st');
      return 'Object';
    } finally {
      // Always close to release native resources
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
    const generic = <String>{
      // ML Kit base model generic categories
      'Plant', 'Organism', 'Natural material', 'Still life photography',
      'Macro photography', 'Nature', 'Close-up', 'Photography',
      'Stock photography', 'Art', 'Creative arts', 'Font',
      // Truly unhelpful
      'Unknown', 'None', 'Entity', 'Thing', 'Item',
      'Material', 'Texture', 'Pattern', 'Background',
      'Scene', 'Outdoor', 'Indoor', 'Room',
    };
    return generic.contains(label);
  }

  void dispose() {
    // No persistent labeler to close
  }
}
