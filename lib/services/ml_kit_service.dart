import 'package:flutter/foundation.dart';
// ML Kit is a native-only package — guard every call with kIsWeb
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class MlKitService {
  static final MlKitService _instance = MlKitService._internal();
  factory MlKitService() => _instance;
  MlKitService._internal();

  /// Label an image by file path.
  /// On Flutter Web this always returns 'Object' immediately because the
  /// native ML Kit SDK is unavailable in browser environments.
  Future<String> labelImage(String imagePath) async {
    // ── Web: ML Kit native SDK is not available ───────────────────────────
    if (kIsWeb) {
      debugPrint('[MlKit] Skipping on web — returning "Object"');
      return 'Object';
    }

    // ── Native (Android / iOS) ────────────────────────────────────────────
    ImageLabeler? labeler;
    try {
      debugPrint('[MlKit] Processing: $imagePath');

      labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.0),
      );

      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await labeler.processImage(inputImage);

      debugPrint('[MlKit] Labels returned: ${labels.length}');
      for (final l in labels) {
        debugPrint(
            '[MlKit]   "${l.label}" — ${(l.confidence * 100).toStringAsFixed(1)}%');
      }

      if (labels.isEmpty) {
        debugPrint('[MlKit] No labels, returning "Object"');
        return 'Object';
      }

      labels.sort((a, b) => b.confidence.compareTo(a.confidence));

      for (final label in labels) {
        final cleaned = _cleanLabel(label.label);
        if (!_isGenericLabel(cleaned)) {
          debugPrint(
              '[MlKit] Best label: "$cleaned" (${(label.confidence * 100).toStringAsFixed(1)}%)');
          return cleaned;
        }
      }

      final top = _cleanLabel(labels.first.label);
      debugPrint('[MlKit] All generic, using top: "$top"');
      return top.isEmpty ? 'Object' : top;
    } catch (e, st) {
      debugPrint('[MlKit] ERROR: $e');
      debugPrint('[MlKit] $st');
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
    const generic = <String>{
      'Plant',
      'Organism',
      'Natural material',
      'Still life photography',
      'Macro photography',
      'Nature',
      'Close-up',
      'Photography',
      'Stock photography',
      'Art',
      'Creative arts',
      'Font',
      'Unknown',
      'None',
      'Entity',
      'Thing',
      'Item',
      'Material',
      'Texture',
      'Pattern',
      'Background',
      'Scene',
      'Outdoor',
      'Indoor',
      'Room',
    };
    return generic.contains(label);
  }

  void dispose() {}
}
