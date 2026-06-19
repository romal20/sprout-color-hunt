import 'package:flutter/material.dart';
import '../utils/asset_helper.dart';

class TwinkleWidget extends StatefulWidget {
  final double size;
  final bool bounce;
  final bool happy;

  const TwinkleWidget({
    super.key,
    this.size = 100,
    this.bounce = true,
    this.happy = true,
  });

  @override
  State<TwinkleWidget> createState() => _TwinkleWidgetState();
}

class _TwinkleWidgetState extends State<TwinkleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.bounce) _ctrl.repeat(reverse: true);
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
      builder: (_, child) => Transform.translate(
        offset: Offset(0, widget.bounce ? _anim.value : 0),
        child: child,
      ),
      child: AssetHelper.safeImage(
        'assets/images/twinkle.png',
        width: widget.size,
        height: widget.size,
        fallback: TwinkleStarWidget(size: widget.size),
      ),
    );
  }
}
