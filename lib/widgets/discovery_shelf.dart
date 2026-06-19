import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_models.dart';

/// Discovery shelf always shows exactly 5 slots — one per rainbow color.
/// Filled slots show the captured image + label. Empty slots show a placeholder.
class DiscoveryShelf extends StatelessWidget {
  final List<Discovery> discoveries;

  const DiscoveryShelf({super.key, required this.discoveries});

  @override
  Widget build(BuildContext context) {
    // Build a map from RainbowColor → Discovery for quick lookup
    final Map<RainbowColor, Discovery> discovered = {};
    for (final d in discoveries) {
      discovered[d.targetColor] = d;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Your Discoveries',
            style: GoogleFonts.fredoka(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334466),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: RainbowColor.values.length, // always 5
            itemBuilder: (_, i) {
              final color = RainbowColor.values[i];
              final discovery = discovered[color];
              if (discovery != null) {
                return _FilledSlot(discovery: discovery);
              } else {
                return _EmptySlot(color: color);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Empty slot — shows the color's dot + icon, waiting to be filled
class _EmptySlot extends StatelessWidget {
  final RainbowColor color;
  const _EmptySlot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.color.withValues(alpha: 0.5), width: 2),
        color: color.color.withValues(alpha: 0.08),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.color.withValues(alpha: 0.3),
              border: Border.all(
                  color: color.color.withValues(alpha: 0.6), width: 1.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            color.displayName,
            style: GoogleFonts.fredoka(
              fontSize: 9,
              color: color.darkColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled slot — shows actual captured image + object label
class _FilledSlot extends StatelessWidget {
  final Discovery discovery;
  const _FilledSlot({required this.discovery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: discovery.targetColor.color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Actual photo
            _DiscoveryImage(discovery: discovery),
            // Dark gradient at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  // Show actual ML Kit label, never hard-code "Object"
                  discovery.objectLabel.isNotEmpty
                      ? discovery.objectLabel
                      : discovery.detectedColor,
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Color dot top-right
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: discovery.targetColor.color,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
            // Checkmark top-left
            Positioned(
              top: 3,
              left: 3,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3CAB31),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful image that evicts Flutter's image cache for its path,
/// so the real captured photo always shows (never a stale frame).
class _DiscoveryImage extends StatefulWidget {
  final Discovery discovery;
  const _DiscoveryImage({required this.discovery});

  @override
  State<_DiscoveryImage> createState() => _DiscoveryImageState();
}

class _DiscoveryImageState extends State<_DiscoveryImage> {
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Only evict file-based cache on native — FileImage crashes on web
    if (!kIsWeb) {
      _evictCacheNative();
    }
  }

  void _evictCacheNative() {
    final path = widget.discovery.imagePath;
    if (path.isEmpty) return;
    try {
      FileImage(File(path)).evict().catchError((_) => false).then((_) {
        if (mounted) setState(() => _error = false);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.discovery.imagePath;
    if (_error || path.isEmpty) return _fallback();

    // ── Web: blob URL — use Image.network ─────────────────────────────────
    if (kIsWeb) {
      return Image.network(
        path,
        key: ValueKey(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _error = true);
          });
          return _fallback();
        },
      );
    }

    // ── Native: file path — use Image.file ────────────────────────────────
    try {
      final file = File(path);
      if (!file.existsSync()) return _fallback();
      return Image.file(
        file,
        key: ValueKey(path),
        fit: BoxFit.cover,
        cacheWidth: 144,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _error = true);
          });
          return _fallback();
        },
      );
    } catch (_) {
      return _fallback();
    }
  }

  Widget _fallback() {
    return Container(
      color: widget.discovery.targetColor.color.withValues(alpha: 0.20),
      child: Icon(Icons.image_rounded,
          color: widget.discovery.targetColor.color, size: 28),
    );
  }
}
