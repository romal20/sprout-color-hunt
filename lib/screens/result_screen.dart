import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../providers/game_provider.dart';
import '../services/tts_service.dart';
import '../services/audio_service.dart';
import '../utils/asset_helper.dart';

// ─────────────────────────────────────────────
// Success Screen
// ─────────────────────────────────────────────
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _starCtrl;
  late Animation<double> _cardScale;
  late Animation<double> _starBounce;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _starCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);

    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack),
    );

    _starBounce = Tween<double>(begin: 1.0, end: 1.28).animate(
      CurvedAnimation(parent: _starCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _playSuccess());
  }

  void _playSuccess() {
    final provider = context.read<GameProvider>();
    AudioService().playSuccess();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        TtsService().speak(provider.currentTargetColor.successMessage);
      }
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _cardCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final color = provider.currentTargetColor;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF12104A),
              color.darkColor.withValues(alpha: 0.75),
              const Color(0xFF1A3A1A),
            ],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _ConfettiPainter(_confettiCtrl.value),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 6),

                  // "Great Job!" title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _starBounce,
                        builder: (_, child) => Transform.scale(
                            scale: _starBounce.value, child: child),
                        child: const Text('⭐', style: TextStyle(fontSize: 30)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Great Job!',
                        style: GoogleFonts.fredoka(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(2, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _starBounce,
                        builder: (_, child) => Transform.scale(
                            scale: _starBounce.value, child: child),
                        child: const Text('⭐', style: TextStyle(fontSize: 30)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Result card
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _cardScale,
                      builder: (_, child) => Transform.scale(
                          scale: _cardScale.value, child: child),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ResultCard(provider: provider, color: color),
                      ),
                    ),
                  ),

                  // Buttons
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      math.max(MediaQuery.of(context).padding.bottom + 12, 20),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            TtsService().stop();
                            if (provider.currentMissionIndex == 4) {
                              provider.triggerCelebration();
                            } else {
                              provider.nextMission();
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5DD85A), Color(0xFF3CAB31)],
                              ),
                              borderRadius: BorderRadius.circular(29),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3CAB31)
                                      .withValues(alpha: 0.45),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                provider.currentMissionIndex == 4
                                    ? '🌈  See My Rainbow!'
                                    : 'Next Mission  →',
                                style: GoogleFonts.fredoka(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final GameProvider provider;
  final RainbowColor color;

  const _ResultCard({required this.provider, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + label row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Captured image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _CapturedImage(
                  imagePath: provider.lastImagePath,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              // Object info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.lastObjectLabel.isNotEmpty
                          ? provider.lastObjectLabel
                          : 'Object',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222244),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Color pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        provider.lastDetectedColor.isNotEmpty
                            ? provider.lastDetectedColor
                            : color.displayName,
                        style: GoogleFonts.fredoka(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Twinkle speech
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AssetHelper.safeImage(
                          'assets/images/twinkle.png',
                          width: 40,
                          height: 40,
                          fallback: const TwinkleStarWidget(size: 40),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EEFF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              color.successMessage,
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF555577),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Awards row
          const Row(
            children: [
              _AwardBadge(
                icon: Icons.star_rounded,
                iconColor: Color(0xFFFFD84D),
                label: '+1 Star',
                labelColor: Color(0xFF8B6914),
                bg: Color(0xFFFFF8E0),
                border: Color(0xFFFFD84D),
              ),
              SizedBox(width: 10),
              _AwardBadge(
                emoji: '🌈',
                label: 'Color Restored!',
                labelColor: Color(0xFF2D7A2D),
                bg: Color(0xFFE8F8E8),
                border: Color(0xFF6BE35F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapturedImage extends StatefulWidget {
  final String imagePath;
  final RainbowColor color;
  const _CapturedImage({required this.imagePath, required this.color});

  @override
  State<_CapturedImage> createState() => _CapturedImageState();
}

class _CapturedImageState extends State<_CapturedImage> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Only evict file-based cache on native — FileImage crashes on web
    if (!kIsWeb) {
      _evictNative();
    }
  }

  void _evictNative() {
    if (widget.imagePath.isEmpty) return;
    try {
      FileImage(File(widget.imagePath)).evict().then((_) {
        if (mounted) setState(() => _hasError = false);
      }).catchError((_) {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[CapturedImage] path="${widget.imagePath}" kIsWeb=$kIsWeb');

    if (_hasError || widget.imagePath.isEmpty) return _placeholder();

    // ── Web: imagePath is a blob URL — use Image.network ──────────────────
    if (kIsWeb) {
      return Image.network(
        widget.imagePath,
        key: ValueKey(widget.imagePath),
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, err, __) {
          debugPrint('[CapturedImage] Image.network error: $err');
          return _placeholder();
        },
      );
    }

    // ── Native: use Image.file ────────────────────────────────────────────
    try {
      final file = File(widget.imagePath);
      if (!file.existsSync()) return _placeholder();
      return Image.file(
        file,
        key: ValueKey(widget.imagePath),
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        cacheWidth: 280,
        errorBuilder: (_, err, __) {
          debugPrint('[CapturedImage] Image.file error: $err');
          return _placeholder();
        },
      );
    } catch (e) {
      debugPrint('[CapturedImage] build error: $e');
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: widget.color.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.image_rounded, size: 56, color: widget.color.color),
    );
  }
}

class _AwardBadge extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String? emoji;
  final String label;
  final Color labelColor;
  final Color bg;
  final Color border;

  const _AwardBadge({
    this.icon,
    this.iconColor,
    this.emoji,
    required this.label,
    required this.labelColor,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: iconColor, size: 18),
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Failure Screen
// ─────────────────────────────────────────────
class FailureScreen extends StatefulWidget {
  const FailureScreen({super.key});

  @override
  State<FailureScreen> createState() => _FailureScreenState();
}

class _FailureScreenState extends State<FailureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() {
    final provider = context.read<GameProvider>();
    final target = provider.currentTargetColor;
    final found = provider.lastDetectedColor.isNotEmpty
        ? provider.lastDetectedColor
        : 'something else';
    TtsService().speak(
      "Oops! I found $found. Let's keep looking for ${target.displayName.toLowerCase()}!",
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final target = provider.currentTargetColor;
    final foundColor = provider.lastDetectedColor.isNotEmpty
        ? provider.lastDetectedColor
        : 'something else';
    final foundObject = provider.lastObjectLabel.isNotEmpty
        ? provider.lastObjectLabel
        : 'Object';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF70CAFF), Color(0xFFB8E8FF), Color(0xFFDFF5FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Twinkle (shaking)
                AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(_shake.value, 0), child: child),
                  child: AssetHelper.safeImage(
                    'assets/images/twinkle.png',
                    width: 100,
                    height: 100,
                    fallback: const TwinkleStarWidget(size: 100),
                  ),
                ),

                const SizedBox(height: 8),

                // Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Not quite! 😅',
                        style: GoogleFonts.fredoka(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333366),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Found object + color row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            foundObject,
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF444466),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              foundColor,
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF555577),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Speech bubble
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          "Oops! I found $foundColor.\nLet's keep looking for ${target.displayName.toLowerCase()}!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF555577),
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Target reminder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Looking for: ",
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              color: const Color(0xFF888899),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: target.color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            target.displayName,
                            style: GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: target.darkColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Try Again button
                GestureDetector(
                  onTap: () {
                    TtsService().stop();
                    provider.backToHunt();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B6DFF), Color(0xFF6C4DFF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6C4DFF).withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '🔍  Try Again!',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(
                    height: math.max(
                        MediaQuery.of(context).padding.bottom + 16, 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Analyzing Screen
// ─────────────────────────────────────────────
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF70CAFF), Color(0xFFB8E8FF)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.rotate(
                  angle: _ctrl.value * 2 * math.pi,
                  child: child,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFFFFD84D), size: 72),
              ),
              const SizedBox(height: 24),
              Text(
                'Looking for colors...',
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333366),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Twinkle is checking! ✨',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  color: const Color(0xFF555577),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Confetti Painter
// ─────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double animValue;

  static final List<_ConfettiPiece> _pieces = List.generate(60, (i) {
    final rng = math.Random(i * 31 + 7);
    return _ConfettiPiece(
      x: rng.nextDouble(),
      speed: rng.nextDouble() * 0.28 + 0.08,
      size: rng.nextDouble() * 10 + 4,
      color: [
        const Color(0xFFFF4444),
        const Color(0xFFFFD84D),
        const Color(0xFF6BE35F),
        const Color(0xFF4AA8FF),
        const Color(0xFF9B59FF),
        const Color(0xFFFF7EDB),
      ][i % 6],
      rotation: rng.nextDouble() * 6.28,
      phase: rng.nextDouble(),
    );
  });

  _ConfettiPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final piece in _pieces) {
      final progress = (animValue * piece.speed + piece.phase) % 1.0;
      final x = piece.x * size.width;
      final y = progress * (size.height + 50) - 25;
      paint.color = piece.color.withValues(alpha: 0.88);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.rotation + animValue * 4);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: piece.size, height: piece.size * 0.5),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.animValue != animValue;
}

class _ConfettiPiece {
  final double x, speed, size, rotation, phase;
  final Color color;
  const _ConfettiPiece({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.phase,
  });
}
