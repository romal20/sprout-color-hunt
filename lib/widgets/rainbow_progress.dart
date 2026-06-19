import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class RainbowProgressWidget extends StatelessWidget {
  final List<bool> completedMissions;
  final int currentMission;

  const RainbowProgressWidget({
    super.key,
    required this.completedMissions,
    required this.currentMission,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(RainbowColor.values.length, (i) {
        final color = RainbowColor.values[i];
        final isCompleted =
            i < completedMissions.length && completedMissions[i];
        final isCurrent = i == currentMission;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _ProgressDot(
            color: color.color,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
          ),
        );
      }),
    );
  }
}

class _ProgressDot extends StatefulWidget {
  final Color color;
  final bool isCompleted;
  final bool isCurrent;

  const _ProgressDot({
    required this.color,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  State<_ProgressDot> createState() => _ProgressDotState();
}

class _ProgressDotState extends State<_ProgressDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isCurrent) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _ProgressDot old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isCurrent && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: widget.isCurrent ? _pulse.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isCompleted
              ? widget.color
              : Colors.white.withValues(alpha: 0.3),
          border: Border.all(
            color: widget.isCompleted
                ? widget.color
                : widget.isCurrent
                    ? widget.color
                    : Colors.white.withValues(alpha: 0.5),
            width: widget.isCurrent ? 3 : 2,
          ),
          boxShadow: widget.isCompleted
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}

// Full animated rainbow arc shown on hunt screen
class RainbowArcWidget extends StatelessWidget {
  final List<bool> completedMissions;

  const RainbowArcWidget({
    super.key,
    required this.completedMissions,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 80),
      painter: _RainbowArcPainter(completedMissions),
    );
  }
}

class _RainbowArcPainter extends CustomPainter {
  final List<bool> completedMissions;

  _RainbowArcPainter(this.completedMissions);

  static const List<Color> colors = [
    Color(0xFFFF4444), // Red
    Color(0xFF4AA8FF), // Blue
    Color(0xFF6BE35F), // Green
    Color(0xFFFFD84D), // Yellow
    Color(0xFF9B59FF), // Purple
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottom = size.height + 20;

    for (int i = 0; i < 5; i++) {
      final isCompleted = i < completedMissions.length && completedMissions[i];
      final factor = 0.9 - (i * 0.12);
      final r = cx * factor;
      final paint = Paint()
        ..color = isCompleted ? colors[i] : colors[i].withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      if (isCompleted) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
      }

      final rect = Rect.fromCircle(center: Offset(cx, bottom), radius: r);
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowArcPainter old) =>
      old.completedMissions != completedMissions;
}
