import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AssetHelper {
  static Widget safeImage(
    String assetPath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? fallback,
  }) {
    return _SafeAssetImage(
      assetPath: assetPath,
      width: width,
      height: height,
      fit: fit,
      fallback: fallback ??
          Icon(Icons.auto_awesome,
              size: (width ?? 48), color: const Color(0xFFFFD84D)),
    );
  }

  static Widget safeLottie(
    String assetPath, {
    double? width,
    double? height,
    bool repeat = true,
    Widget? fallback,
  }) {
    return _SafeLottie(
      assetPath: assetPath,
      width: width,
      height: height,
      repeat: repeat,
      fallback: fallback ??
          SizedBox(
            width: width ?? 100,
            height: height ?? 100,
            child: const _PulseAnimation(),
          ),
    );
  }
}

class _SafeAssetImage extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget fallback;

  const _SafeAssetImage({
    required this.assetPath,
    this.width,
    this.height,
    required this.fit,
    required this.fallback,
  });

  @override
  State<_SafeAssetImage> createState() => _SafeAssetImageState();
}

class _SafeAssetImageState extends State<_SafeAssetImage> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (_error) return widget.fallback;
    return Image.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) {
        if (mounted && !_error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _error = true);
          });
        }
        return widget.fallback;
      },
    );
  }
}

class _SafeLottie extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool repeat;
  final Widget fallback;

  const _SafeLottie({
    required this.assetPath,
    this.width,
    this.height,
    required this.repeat,
    required this.fallback,
  });

  @override
  State<_SafeLottie> createState() => _SafeLottieState();
}

class _SafeLottieState extends State<_SafeLottie> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (_error) return widget.fallback;
    return Lottie.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      repeat: widget.repeat,
      errorBuilder: (_, __, ___) {
        if (mounted && !_error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _error = true);
          });
        }
        return widget.fallback;
      },
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation();

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD84D), size: 48),
    );
  }
}

// Custom Twinkle star widget used as fallback when twinkle.png is missing
class TwinkleStarWidget extends StatefulWidget {
  final double size;
  const TwinkleStarWidget({super.key, this.size = 120});

  @override
  State<TwinkleStarWidget> createState() => _TwinkleStarWidgetState();
}

class _TwinkleStarWidgetState extends State<TwinkleStarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _bounce.value), child: child),
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _StarFacePainter(),
      ),
    );
  }
}

class _StarFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerR = size.width * 0.46;
    final double innerR = size.width * 0.2;

    // Draw star body
    final path = _starPath(cx, cy, outerR, innerR, 5);

    final shadow = Paint()
      ..color = const Color(0xFFE6A800).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, shadow);

    final body = Paint()
      ..color = const Color(0xFFFFD84D)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, body);

    final outline = Paint()
      ..color = const Color(0xFFE6A800)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    canvas.drawPath(path, outline);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.11, cy - size.height * 0.03),
        width: size.width * 0.075,
        height: size.height * 0.095,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.11, cy - size.height * 0.03),
        width: size.width * 0.075,
        height: size.height * 0.095,
      ),
      eyePaint,
    );

    // White glints
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.115, cy - size.height * 0.045),
        width: size.width * 0.025,
        height: size.height * 0.03,
      ),
      glintPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.105, cy - size.height * 0.045),
        width: size.width * 0.025,
        height: size.height * 0.03,
      ),
      glintPaint,
    );

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF4A3000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;
    final smilePath = Path();
    smilePath.moveTo(cx - size.width * 0.1, cy + size.height * 0.06);
    smilePath.quadraticBezierTo(
      cx,
      cy + size.height * 0.18,
      cx + size.width * 0.1,
      cy + size.height * 0.06,
    );
    canvas.drawPath(smilePath, smilePaint);

    // Rosy cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF9999).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - size.width * 0.19, cy + size.height * 0.05),
        width: size.width * 0.13,
        height: size.height * 0.07,
      ),
      cheekPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + size.width * 0.19, cy + size.height * 0.05),
        width: size.width * 0.13,
        height: size.height * 0.07,
      ),
      cheekPaint,
    );
  }

  Path _starPath(
      double cx, double cy, double outerR, double innerR, int points) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
