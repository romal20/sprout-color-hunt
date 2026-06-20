import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/tts_service.dart';
import '../services/audio_service.dart';
import '../widgets/twinkle_widget.dart';

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiCtrl;
  late AnimationController _rainbowCtrl;
  late AnimationController _badgeCtrl;
  late AnimationController _starsCtrl;
  late Animation<double> _rainbowScale;
  late Animation<double> _badgeSlide;
  late Animation<double> _starsSpin;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _rainbowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rainbowScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rainbowCtrl, curve: Curves.elasticOut),
    );

    _badgeSlide = Tween<double>(begin: 80, end: 0).animate(
      CurvedAnimation(parent: _badgeCtrl, curve: Curves.easeOutBack),
    );

    _starsSpin = Tween<double>(begin: 0, end: 1).animate(_starsCtrl);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _badgeCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      AudioService().playCelebration();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          TtsService().speak("You fixed my rainbow! You are a Rainbow Hero!");
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _rainbowCtrl.dispose();
    _badgeCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0B3A),
              Color(0xFF1A2580),
              Color(0xFF3B1F8C),
              Color(0xFF6C4DFF),
            ],
            stops: [0.0, 0.3, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Confetti
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _CelebConfettiPainter(_confettiCtrl.value),
              ),
            ),

            // Twinkling stars
            AnimatedBuilder(
              animation: _starsSpin,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _TwinkleStarsPainter(_starsSpin.value),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    22, 16, 22, math.max(bottomPad + 16, 24)),
                child: Column(
                  children: [
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFD84D),
                          Color(0xFFFF9A3C),
                          Color(0xFFFF5C5C),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        '🌈 You Did It! 🌈',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'You fixed my rainbow!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Rainbow arc
                    AnimatedBuilder(
                      animation: _rainbowScale,
                      builder: (_, child) => Transform.scale(
                          scale: _rainbowScale.value, child: child),
                      child: SizedBox(
                        width: size.width - 44,
                        height: (size.width - 44) * 0.58,
                        child: CustomPaint(painter: _FullRainbowPainter()),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const TwinkleWidget(size: 96, bounce: true),

                    const SizedBox(height: 10),

                    // Speech bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '"You fixed my rainbow!\nYou are a Rainbow Hero!" 🌟',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 17,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Rainbow Hero badge
                    AnimatedBuilder(
                      animation: _badgeSlide,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _badgeSlide.value),
                        child: child,
                      ),
                      child: _RainbowHeroBadge(stars: provider.stars),
                    ),

                    const SizedBox(height: 26),

                    // Play Again
                    GestureDetector(
                      onTap: () {
                        TtsService().stop();
                        AudioService().stopAll();
                        provider.resetGame();
                      },
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD84D), Color(0xFFFF9A3C)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD84D)
                                  .withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '🎮  Play Again!',
                            style: GoogleFonts.fredoka(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        TtsService().stop();
                        AudioService().stopAll();
                        provider.resetGame();
                      },
                      child: Text(
                        'Return Home',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Rainbow Hero Badge
// ─────────────────────────────────────────────
class _RainbowHeroBadge extends StatelessWidget {
  final int stars;
  const _RainbowHeroBadge({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD84D), Color(0xFFFF9A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD84D).withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rainbow Hero!',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$stars / 5 Stars Earned',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Full Rainbow Painter
// ─────────────────────────────────────────────
class _FullRainbowPainter extends CustomPainter {
  static const List<Color> _colors = [
    Color(0xFFFF4444),
    Color(0xFFFF8C00),
    Color(0xFFFFD84D),
    Color(0xFF6BE35F),
    Color(0xFF4AA8FF),
    Color(0xFF6C4DFF),
    Color(0xFFFF7EDB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height + 30.0;

    for (int i = 0; i < _colors.length; i++) {
      final fraction = 1.0 - i * 0.10;
      final r = cx * fraction;

      final glowPaint = Paint()
        ..color = _colors[i].withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final paint = Paint()
        ..color = _colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: Offset(cx, bottom), radius: r);
      canvas.drawArc(rect, math.pi, math.pi, false, glowPaint);
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Confetti Painter
// ─────────────────────────────────────────────
class _CelebConfettiPainter extends CustomPainter {
  final double animValue;

  static final List<_CelebPiece> _pieces = List.generate(80, (i) {
    final rng = math.Random(i * 17 + 3);
    return _CelebPiece(
      x: rng.nextDouble(),
      speed: rng.nextDouble() * 0.25 + 0.08,
      size: rng.nextDouble() * 12 + 4,
      color: [
        const Color(0xFFFF4444),
        const Color(0xFFFFD84D),
        const Color(0xFF6BE35F),
        const Color(0xFF4AA8FF),
        const Color(0xFF9B59FF),
        const Color(0xFFFF7EDB),
        Colors.white,
      ][i % 7],
      rotation: rng.nextDouble() * 6.28,
      phase: rng.nextDouble(),
      isCircle: i % 3 == 0,
    );
  });

  _CelebConfettiPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _pieces) {
      final progress = (animValue * p.speed + p.phase) % 1.0;
      final x = p.x * size.width;
      final y = progress * (size.height + 60) - 30;
      paint.color = p.color.withValues(alpha: 0.9);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + animValue * 5);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebConfettiPainter old) =>
      old.animValue != animValue;
}

class _CelebPiece {
  final double x, speed, size, rotation, phase;
  final Color color;
  final bool isCircle;
  const _CelebPiece({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.phase,
    required this.isCircle,
  });
}

// ─────────────────────────────────────────────
// Stars Background Painter
// ─────────────────────────────────────────────
class _TwinkleStarsPainter extends CustomPainter {
  final double animValue;

  static final List<_StarParticle> _particles = List.generate(30, (i) {
    final rng = math.Random(i * 13 + 5);
    return _StarParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 5 + 1.5,
      phase: rng.nextDouble(),
    );
  });

  _TwinkleStarsPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final brightness =
          0.25 + 0.75 * math.sin((animValue + p.phase) * 2 * math.pi);
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TwinkleStarsPainter old) =>
      old.animValue != animValue;
}

class _StarParticle {
  final double x, y, size, phase;
  const _StarParticle(
      {required this.x,
      required this.y,
      required this.size,
      required this.phase});
}
