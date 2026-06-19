import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/tts_service.dart';
import '../utils/asset_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _starsCtrl;
  late AnimationController _twinkleCtrl;
  late AnimationController _bubbleCtrl;
  late AnimationController _buttonCtrl;
  late Animation<double> _twinkleBounce;
  late Animation<double> _bubble1Scale;
  late Animation<double> _bubble2Scale;
  late Animation<double> _buttonPulse;

  @override
  void initState() {
    super.initState();
    _starsCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _twinkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _buttonCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

    _twinkleBounce = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _twinkleCtrl, curve: Curves.easeInOut),
    );
    _bubble1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bubbleCtrl, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _bubble2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bubbleCtrl, curve: const Interval(0.45, 1.0, curve: Curves.elasticOut)),
    );
    _buttonPulse = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _buttonCtrl, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) TtsService().speak("My rainbow lost its colors. Can you help me find them?");
    });
  }

  @override
  void dispose() {
    _starsCtrl.dispose();
    _twinkleCtrl.dispose();
    _bubbleCtrl.dispose();
    _buttonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    // Twinkle size capped so it never crowds the button
    final twinkleSize = math.min(size.width * 0.32, 130.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060B2E),
              Color(0xFF0D1F6E),
              Color(0xFF1A3BAF),
              Color(0xFF5035CC),
              Color(0xFF8B5CF6),
            ],
            stops: [0.0, 0.22, 0.50, 0.78, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Stars background
            AnimatedBuilder(
              animation: _starsCtrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _StarfieldPainter(_starsCtrl.value),
              ),
            ),

            // Moon — top right, sized smaller
            Positioned(
              top: topPad + 16,
              right: size.width * 0.06,
              child: _MoonWidget(size: size.width * 0.12),
            ),

            // Scattered sparkles
            ..._buildSparkles(size),

            // Clouds — anchored above rainbow
            Positioned(
              bottom: size.height * 0.10,
              left: 0,
              right: 0,
              child: const _CloudLayer(),
            ),

            // Rainbow — smaller: 30% of screen height from bottom, reduced width
            Positioned(
              bottom: 0,
              left: size.width * 0.05,
              right: size.width * 0.05,
              child: _RainbowOutline(width: size.width * 0.90),
            ),

            // ── Main Column ──
            // Uses a strict Column so the button always sits above the rainbow
            // and Twinkle+bubbles never overlap the button.
            Padding(
              padding: EdgeInsets.only(top: topPad, bottom: math.max(botPad, 0)),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Title — no logo image
                  _RainbowTitle(),

                  const SizedBox(height: 6),

                  // Twinkle + speech bubbles — flex to fill remaining space
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final areaH = constraints.maxHeight;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: size.width * 0.06),

                            // Twinkle star
                            AnimatedBuilder(
                              animation: _twinkleBounce,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(0, _twinkleBounce.value),
                                child: child,
                              ),
                              child: _buildTwinkle(twinkleSize),
                            ),

                            const SizedBox(width: 16),

                            // Speech bubbles stacked vertically
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedBuilder(
                                    animation: _bubble1Scale,
                                    builder: (_, child) => Transform.scale(
                                      scale: _bubble1Scale.value,
                                      alignment: Alignment.bottomLeft,
                                      child: child,
                                    ),
                                    child: _SpeechBubble(
                                      text: 'My rainbow\nlost its colors!',
                                      maxWidth: size.width * 0.46,
                                    ),
                                  ),
                                  SizedBox(height: areaH * 0.06),
                                  AnimatedBuilder(
                                    animation: _bubble2Scale,
                                    builder: (_, child) => Transform.scale(
                                      scale: _bubble2Scale.value,
                                      alignment: Alignment.bottomLeft,
                                      child: child,
                                    ),
                                    child: _SpeechBubble(
                                      text: 'Can you help\nme find them?',
                                      maxWidth: size.width * 0.46,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: size.width * 0.04),
                          ],
                        );
                      },
                    ),
                  ),

                  // ── Start Hunt button ── always visible, separated by fixed space
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      size.width * 0.1,
                      4,
                      size.width * 0.1,
                      // Sit above the rainbow (≈30% of screen) + safe area
                      math.max(size.height * 0.30 + botPad, 80),
                    ),
                    child: AnimatedBuilder(
                      animation: _buttonPulse,
                      builder: (_, child) => Transform.scale(scale: _buttonPulse.value, child: child),
                      child: _StartButton(
                        onTap: () {
                          TtsService().stop();
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

  Widget _buildTwinkle(double sz) {
    return AssetHelper.safeImage(
      'assets/images/twinkle.png',
      width: sz,
      height: sz,
      fallback: TwinkleStarWidget(size: sz),
    );
  }

  List<Widget> _buildSparkles(Size size) {
    const positions = [
      [0.12, 0.10],
      [0.72, 0.07],
      [0.52, 0.16],
      [0.86, 0.20],
      [0.06, 0.26],
    ];
    return positions.asMap().entries.map((e) {
      return Positioned(
        left: e.value[0] * size.width,
        top: e.value[1] * size.height,
        child: _SparkleWidget(delay: e.key * 0.2),
      );
    }).toList();
  }
}

// ─────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────

class _SparkleWidget extends StatefulWidget {
  final double delay;
  const _SparkleWidget({required this.delay});
  @override
  State<_SparkleWidget> createState() => _SparkleWidgetState();
}

class _SparkleWidgetState extends State<_SparkleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward(from: widget.delay % 1.0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: const Text('✨', style: TextStyle(fontSize: 16)),
    );
  }
}

class _RainbowTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Twinkle's",
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: const [Shadow(color: Color(0x886C4DFF), offset: Offset(0, 2), blurRadius: 6)],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF5C5C), Color(0xFFFFD84D), Color(0xFF6BE35F), Color(0xFF4AA8FF), Color(0xFFB87FFF)],
          ).createShader(bounds),
          child: Text(
            'Rainbow',
            style: GoogleFonts.fredoka(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.0,
              shadows: const [Shadow(color: Colors.black38, offset: Offset(2, 3), blurRadius: 6)],
            ),
          ),
        ),
        Text(
          'Hunt',
          style: GoogleFonts.fredoka(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFFD84D),
            letterSpacing: 2.0,
            shadows: const [Shadow(color: Colors.black38, offset: Offset(1, 3), blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final double maxWidth;
  const _SpeechBubble({required this.text, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF333366), height: 1.3),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9B6DFF), Color(0xFF6C4DFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: const Color(0xFF6C4DFF).withValues(alpha: 0.55), blurRadius: 20, offset: const Offset(0, 7))],
        ),
        child: Center(
          child: Text('Start Hunt', style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class _MoonWidget extends StatelessWidget {
  final double size;
  const _MoonWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF8D0),
            boxShadow: [BoxShadow(color: const Color(0xFFFFF8D0).withValues(alpha: 0.4), blurRadius: 18, spreadRadius: 4)],
          ),
        ),
        Positioned(
          right: size * 0.06,
          top: size * 0.06,
          child: Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D1F6E)),
          ),
        ),
      ],
    );
  }
}

class _CloudLayer extends StatelessWidget {
  const _CloudLayer();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return SizedBox(
      height: 55,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -8, bottom: 0, child: _Cloud(width: w * 0.40, height: 42)),
          Positioned(right: -8, bottom: 0, child: _Cloud(width: w * 0.40, height: 42)),
          Positioned(left: w * 0.30, bottom: 10, child: _Cloud(width: w * 0.28, height: 34)),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double width;
  final double height;
  const _Cloud({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)],
      ),
    );
  }
}

// Rainbow is now smaller — width passed in, height = width * 0.35 (was 0.45)
class _RainbowOutline extends StatelessWidget {
  final double width;
  const _RainbowOutline({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.35,
      child: CustomPaint(painter: _RainbowOutlinePainter()),
    );
  }
}

class _RainbowOutlinePainter extends CustomPainter {
  static const List<Color> _colors = [
    Color(0xFFFF5C5C), Color(0xFFFF9A3C), Color(0xFFFFD84D),
    Color(0xFF6BE35F), Color(0xFF4AA8FF), Color(0xFF6C4DFF), Color(0xFFFF7EDB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height + 8.0;
    for (int i = 0; i < _colors.length; i++) {
      final paint = Paint()
        ..color = _colors[i].withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round;
      final fraction = 1.0 - i * 0.11;
      final r = cx * fraction;
      final rect = Rect.fromCircle(center: Offset(cx, bottom), radius: r);
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarfieldPainter extends CustomPainter {
  final double animValue;

  static final List<_StarData> _stars = List.generate(50, (i) {
    final rng = math.Random(i * 7 + 13);
    return _StarData(x: rng.nextDouble(), y: rng.nextDouble() * 0.65, size: rng.nextDouble() * 2.2 + 0.7, phase: rng.nextDouble());
  });

  _StarfieldPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final star in _stars) {
      final brightness = 0.35 + 0.65 * math.sin((animValue + star.phase) * 2 * math.pi);
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(star.x * size.width, star.y * size.height), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter old) => old.animValue != animValue;
}

class _StarData {
  final double x, y, size, phase;
  const _StarData({required this.x, required this.y, required this.size, required this.phase});
}
