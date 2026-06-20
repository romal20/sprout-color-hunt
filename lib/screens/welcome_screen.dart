import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/tts_service.dart';
import '../services/audio_service.dart';
import '../utils/asset_helper.dart';

// ─── TwinkleStarWidget forward-declaration import ────────────────────────────
// asset_helper.dart already exports TwinkleStarWidget, so no extra import needed.

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late AnimationController _starsCtrl; // starfield twinkle loop
  late AnimationController _floatCtrl; // Twinkle star float
  late AnimationController _bubbleCtrl; // speech bubble pop-in
  late AnimationController _buttonCtrl; // start button pulse

  // ── Animations ───────────────────────────────────────────────────────────────
  late Animation<double> _floatAnim;
  late Animation<double> _bubble1Scale;
  late Animation<double> _bubble2Scale;
  late Animation<double> _buttonPulse;

  @override
  void initState() {
    super.initState();

    _starsCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();

    _buttonCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -14.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _bubble1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _bubbleCtrl,
          curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _bubble2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _bubbleCtrl,
          curve: const Interval(0.40, 1.0, curve: Curves.elasticOut)),
    );
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        TtsService()
            .speak("My rainbow lost its colors. Can you help me find them?");
      }
    });
  }

  @override
  void dispose() {
    _starsCtrl.dispose();
    _floatCtrl.dispose();
    _bubbleCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    // Twinkle at ~45% of screen width, capped at 180
    final twinkleSize = math.min(size.width * 0.45, 180.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Reference: deep navy → royal blue → mid-blue → soft purple
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF08082E), // very dark navy top
              Color(0xFF0E1B6E), // deep blue
              Color(0xFF1A3FC2), // royal blue mid
              Color(0xFF3A5FE8), // bright blue
              Color(0xFF6B5BE8), // periwinkle / lavender bottom
            ],
            stops: [0.0, 0.18, 0.45, 0.72, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Starfield ────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _starsCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _StarfieldPainter(_starsCtrl.value),
              ),
            ),

            // ── Scattered sparkle dots ────────────────────────────────────────
            ..._buildSparkles(size, topPad),

            // ── Moon — top left per reference ────────────────────────────────
            Positioned(
              top: topPad + 14,
              left: size.width * 0.06,
              child: _MoonWidget(size: math.min(size.width * 0.16, 68.0)),
            ),

            // ── Rainbow — bottom decorative, white/glowing outlines ───────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomRainbow(screenWidth: size.width),
            ),

            // ── Fluffy layered clouds ────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _FluffyClouds(screenWidth: size.width),
            ),

            // ── Main content column ───────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Title block — focal point at top
                  const SizedBox(height: 8),
                  _RainbowTitle(),

                  const SizedBox(height: 12),

                  // Twinkle + bubbles row — fills middle space
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Twinkle with float + glow
                          AnimatedBuilder(
                            animation: _floatAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _floatAnim.value),
                              child: child,
                            ),
                            child: _GlowingTwinkle(size: twinkleSize),
                          ),

                          SizedBox(width: size.width * 0.04),

                          // Speech bubbles
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ScaleTransition(
                                  scale: _bubble1Scale,
                                  alignment: Alignment.bottomLeft,
                                  child: _CloudBubble(
                                    text: 'My rainbow\nlost its colors!',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ScaleTransition(
                                  scale: _bubble2Scale,
                                  alignment: Alignment.bottomLeft,
                                  child: _CloudBubble(
                                    text: 'Can you help\nme find them?',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Start Hunt button — anchored above clouds/rainbow
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      size.width * 0.08,
                      8,
                      size.width * 0.08,
                      math.max(size.height * 0.22 + botPad, 60),
                    ),
                    child: ScaleTransition(
                      scale: _buttonPulse,
                      child: _StartButton(
                        onTap: () {
                          TtsService().stop();
                          AudioService().playChime();
                          context.read<GameProvider>().startHunt();
                        },
                      ),
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

  List<Widget> _buildSparkles(Size size, double topPad) {
    // Spread across top 70% of screen — matches reference star placement
    const specs = [
      [0.08, 0.06, 14.0, 0.0],
      [0.78, 0.04, 12.0, 0.3],
      [0.55, 0.12, 10.0, 0.5],
      [0.88, 0.18, 13.0, 0.1],
      [0.18, 0.22, 11.0, 0.7],
      [0.65, 0.28, 9.0, 0.4],
      [0.35, 0.08, 10.0, 0.6],
      [0.92, 0.32, 12.0, 0.2],
      [0.04, 0.38, 10.0, 0.8],
      [0.72, 0.42, 11.0, 0.15],
    ];
    return specs.map((s) {
      return Positioned(
        left: s[0] * size.width,
        top: topPad + s[1] * size.height,
        child: _TwinkleDot(size: s[2], delay: s[3]),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TwinkleDot — small four-point star sparkle that pulses
// ─────────────────────────────────────────────────────────────────────────────
class _TwinkleDot extends StatefulWidget {
  final double size;
  final double delay;
  const _TwinkleDot({required this.size, required this.delay});

  @override
  State<_TwinkleDot> createState() => _TwinkleDotState();
}

class _TwinkleDotState extends State<_TwinkleDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward(from: widget.delay % 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _FourPointStarPainter(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FourPointStarPainter extends CustomPainter {
  final Color color;
  const _FourPointStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.3;

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / 4) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _MoonWidget — crescent in top-left, matching reference
// ─────────────────────────────────────────────────────────────────────────────
class _MoonWidget extends StatelessWidget {
  final double size;
  const _MoonWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outer glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF5B0),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFF5B0).withValues(alpha: 0.55),
                blurRadius: 22,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        // Bite out of top-right to create crescent
        Positioned(
          right: size * 0.04,
          top: size * 0.04,
          child: Container(
            width: size * 0.76,
            height: size * 0.76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // match the background top color exactly
              color: const Color(0xFF0A0A2E),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RainbowTitle — "Twinkle's / Rainbow / Hunt" matching reference
// ─────────────────────────────────────────────────────────────────────────────
class _RainbowTitle extends StatelessWidget {
  const _RainbowTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // "Twinkle's" — white, medium
        Text(
          "Twinkle's",
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(
                  color: Color(0xFF000033),
                  offset: Offset(0, 2),
                  blurRadius: 8),
            ],
          ),
        ),
        // "Rainbow" — large multicolor gradient, main focal point
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF4444), // red
              Color(0xFFFF9933), // orange
              Color(0xFFFFDD00), // yellow
              Color(0xFF44CC44), // green
              Color(0xFF44AAFF), // blue
              Color(0xFFBB66FF), // purple
            ],
          ).createShader(bounds),
          child: Text(
            'Rainbow',
            style: GoogleFonts.fredoka(
              fontSize: 58,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: const [
                Shadow(
                    color: Colors.black45,
                    offset: Offset(2, 4),
                    blurRadius: 10),
                Shadow(
                    color: Color(0x66FFFFFF),
                    offset: Offset(0, -1),
                    blurRadius: 8),
              ],
            ),
          ),
        ),
        // "Hunt" — cyan/sky blue matching reference
        Text(
          'Hunt',
          style: GoogleFonts.fredoka(
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7EDDFF),
            letterSpacing: 2.5,
            shadows: const [
              Shadow(
                  color: Colors.black38, offset: Offset(1, 3), blurRadius: 8),
              Shadow(
                  color: Color(0x884AA8FF),
                  offset: Offset(0, 0),
                  blurRadius: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlowingTwinkle — large Twinkle star with soft radial glow behind it
// ─────────────────────────────────────────────────────────────────────────────
class _GlowingTwinkle extends StatelessWidget {
  final double size;
  const _GlowingTwinkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow halo
        Container(
          width: size * 1.28,
          height: size * 1.28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFD84D).withValues(alpha: 0.30),
                const Color(0xFFFFD84D).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Twinkle image (or fallback star)
        AssetHelper.safeImage(
          'assets/images/twinkle.png',
          width: size,
          height: size,
          fallback: TwinkleStarWidget(size: size),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CloudBubble — puffy cloud-style speech bubble matching reference
// ─────────────────────────────────────────────────────────────────────────────
class _CloudBubble extends StatelessWidget {
  final String text;
  const _CloudBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2A2A5A),
          height: 1.35,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StartButton — large purple pill button with glow
// ─────────────────────────────────────────────────────────────────────────────
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9B70FF), Color(0xFF6C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C4DFF).withValues(alpha: 0.65),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF9B70FF).withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Start Hunt',
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.8,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomRainbow — white/translucent concentric arcs in bottom portion
// Matches reference: compact, glowing white outline style
// ─────────────────────────────────────────────────────────────────────────────
class _BottomRainbow extends StatelessWidget {
  final double screenWidth;
  const _BottomRainbow({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    // Height = 42% of width so arcs are compact, not overpowering
    final w = screenWidth;
    final h = w * 0.42;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(painter: _WhiteRainbowPainter()),
    );
  }
}

class _WhiteRainbowPainter extends CustomPainter {
  // 5 concentric arcs, white with subtle alpha — matches reference
  static const List<double> _alphas = [0.90, 0.72, 0.54, 0.38, 0.24];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Push center below bottom edge so arcs appear as gentle half-circles
    final bottom = size.height + 10.0;

    for (int i = 0; i < _alphas.length; i++) {
      final fraction = 1.0 - i * 0.15;
      final r = (cx * 0.95) * fraction;

      // Soft glow layer
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: _alphas[i] * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // Crisp line layer
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: _alphas[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: Offset(cx, bottom), radius: r);
      canvas.drawArc(rect, math.pi, math.pi, false, glowPaint);
      canvas.drawArc(rect, math.pi, math.pi, false, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _FluffyClouds — layered peach/pink fluffy clouds at the bottom
// Matches reference: soft rounded blobs, slightly pink/cream tinted
// ─────────────────────────────────────────────────────────────────────────────
class _FluffyClouds extends StatelessWidget {
  final double screenWidth;
  const _FluffyClouds({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth,
      height: screenWidth * 0.32,
      child: CustomPaint(painter: _FluffyCloudsPainter()),
    );
  }
}

class _FluffyCloudsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Two layers: back (more transparent) and front (opaque)
    _drawCloudLayer(canvas, size, yFactor: 0.70, alpha: 0.55, scale: 1.0);
    _drawCloudLayer(canvas, size, yFactor: 0.85, alpha: 0.80, scale: 0.88);
    _drawCloudLayer(canvas, size, yFactor: 1.0, alpha: 1.0, scale: 0.80);
  }

  void _drawCloudLayer(
    Canvas canvas,
    Size size, {
    required double yFactor,
    required double alpha,
    required double scale,
  }) {
    // Pinkish-peach colour matching reference bottom clouds
    final paint = Paint()
      ..color = const Color(0xFFF5C8E8).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFFD9A0D0).withValues(alpha: alpha * 0.4)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final y = size.height * yFactor;
    final w = size.width;

    // Left cloud cluster
    _drawPuffyCloud(canvas, paint, shadowPaint,
        cx: w * 0.12, cy: y, r: w * 0.10 * scale);

    // Centre-left cloud
    _drawPuffyCloud(canvas, paint, shadowPaint,
        cx: w * 0.32, cy: y + 4, r: w * 0.13 * scale);

    // Centre cloud — tallest
    _drawPuffyCloud(canvas, paint, shadowPaint,
        cx: w * 0.52, cy: y - 2, r: w * 0.11 * scale);

    // Centre-right cloud
    _drawPuffyCloud(canvas, paint, shadowPaint,
        cx: w * 0.70, cy: y + 6, r: w * 0.13 * scale);

    // Right cloud cluster
    _drawPuffyCloud(canvas, paint, shadowPaint,
        cx: w * 0.90, cy: y, r: w * 0.10 * scale);
  }

  void _drawPuffyCloud(
    Canvas canvas,
    Paint paint,
    Paint shadowPaint, {
    required double cx,
    required double cy,
    required double r,
  }) {
    // 3-circle puff: top-centre, left-shoulder, right-shoulder
    canvas.drawCircle(Offset(cx, cy), r, shadowPaint);
    canvas.drawCircle(
        Offset(cx - r * 0.55, cy + r * 0.35), r * 0.78, shadowPaint);
    canvas.drawCircle(
        Offset(cx + r * 0.55, cy + r * 0.35), r * 0.78, shadowPaint);

    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawCircle(Offset(cx - r * 0.55, cy + r * 0.35), r * 0.78, paint);
    canvas.drawCircle(Offset(cx + r * 0.55, cy + r * 0.35), r * 0.78, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _StarfieldPainter — twinkling dots spread across full screen
// ─────────────────────────────────────────────────────────────────────────────
class _StarfieldPainter extends CustomPainter {
  final double animValue;

  static final List<_StarData> _stars = List.generate(80, (i) {
    final rng = math.Random(i * 7 + 13);
    return _StarData(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.78, // spread across upper 78% of screen
      size: rng.nextDouble() * 2.4 + 0.6,
      phase: rng.nextDouble(),
    );
  });

  const _StarfieldPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      final brightness =
          0.25 + 0.75 * math.sin((animValue + star.phase) * 2 * math.pi);
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) =>
      old.animValue != animValue;
}

class _StarData {
  final double x, y, size, phase;
  const _StarData({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
  });
}
